# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require "securerandom"
require "io/nonblock"
require_relative "env"
require_relative "commands"
require_relative "process_title_updater"

module OpenHAB
  module Thermos
    # Preloads openHAB once and executes each command in an isolated ScriptEngine.
    class Runtime
      attr_reader :manager, :background_env, :original_env

      def self.active? = (@active == true)

      def initialize(manager, original_env, background_env = Env.new)
        @manager = manager
        @original_env = original_env
        @background_env = background_env
        @interrupt = IO.pipe
      end

      def app_name = background_env.app_name
      def log(message) = background_env.log("[runtime] #{message}")
      def preloaded? = @preloaded == true

      def preload
        self.class.instance_variable_set(:@active, true)
        require "java"
        require "bundler/setup"
        @preloaded = true
      end

      # The command might need to require some files in the
      # main process so that they are cached. For example a test command wants to
      # load the helper file once and have it cached.
      def setup(command)
        command.setup
      end

      def prepare_engine_factory
        return if @factory

        OpenHAB::RSpec::Helpers.install_addon("automation-jrubyscripting")
        @factory = OpenHAB::OSGi.service(
          "org.openhab.core.automation.module.script.ScriptEngineFactory",
          filter: "(service.pid=org.openhab.automation.jrubyscripting)"
        )
        raise "JRuby Scripting engine factory is unavailable" unless @factory
      end

      def run
        manager.puts
        until @terminating
          ready = IO.select([manager, @interrupt.first]).first
          break if @terminating
          next unless ready.include?(manager)

          begin
            break unless manager.sysread(1) == "R"
          rescue EOFError
            break
          end

          # JRuby may leave a socket nonblocking after sysread. The descriptor
          # can arrive separately from the request byte.
          manager.nonblock = false
          serve(manager.recv_io(UNIXSocket))
        end
      ensure
        manager.close
        @interrupt.each(&:close)
      end

      def serve(client)
        manager.puts
        manager.puts Process.pid
        streams = Array.new(3) { client.recv_io }
        streams.each { |stream| stream.sync = true }
        request = JSON.parse(client.read(client.gets.to_i))
        begin
          preload unless preloaded?
          setup Thermos.command(request.fetch("args").first)
          prepare_engine_factory
          client.puts(0)
        rescue Exception => e
          print_exception(streams[1], e)
          client.puts(1)
          @terminating = true
          return
        end
        client.puts Process.pid
        status = run_engine(request, streams, client)
        client.puts(status)
      rescue Exception => e
        unless e.is_a?(Errno::EPIPE) || e.is_a?(Errno::ECONNRESET)
          print_exception(streams[1], e) if streams
          begin
            client.puts(1)
          rescue
            nil
          end
        end
      ensure
        streams&.each { |stream| stream.close unless stream.closed? }
        client.close
        manager.puts("done")
      end

      def run_engine(request, streams, client)
        factory = @factory
        output, error, input = streams
        error.puts "Running via background runtime in process #{Process.pid}" unless Thermos.quiet

        identifier = "rspec-#{SecureRandom.uuid}"
        extensions = OpenHAB::OSGi.service(
          "org.openhab.core.automation.module.script.internal.ScriptExtensionManager"
        )
        # The launcher sets jruby.home for its own runtime. Embedded engines use the addon's bundled stdlib.
        properties = {
          "jruby.home" => "uri:classloader:/META-INF/jruby.home",
          "jruby.lib" => nil,
          "jruby.bindir" => RbConfig::CONFIG["bindir"],
          "org.jruby.embed.localcontext.scope" => "singlethread"
        }
        previous_properties = properties.to_h { |key, _| [key, java.lang.System.get_property(key)] }
        properties.each do |key, value|
          value ? java.lang.System.set_property(key, value) : java.lang.System.clear_property(key)
        end
        engine = factory.create_script_engine("application/x-ruby")
        raise "Unable to create JRuby engine" unless engine

        container = org.openhab.core.automation.module.script.ScriptEngineContainer.new(engine, factory, identifier)
        wrapper = org.openhab.core.automation.module.script.internal.ScriptExtensionManagerWrapperImpl
                     .new(extensions, container)
        factory.scope_values(engine, java.util.HashMap.new("se" => wrapper, "scriptExtension" => wrapper))
        presets = extensions.find_default_presets(identifier)
        # Defer the addon's automatic requires until the test mocks have been installed.
        presets.put("$ir", presets.remove("ir"))
        factory.scope_values(engine, presets)
        engine.context.set_attribute("oh.engine-identifier", identifier, javax.script.ScriptContext::ENGINE_SCOPE)
        engine.context.set_attribute("oh.extension-accessor", extensions, javax.script.ScriptContext::ENGINE_SCOPE)
        timer_factory = OpenHAB::OSGi.service(
          "org.openhab.core.automation.handler.ModuleHandlerFactory",
          filter: "(component.name=org.openhab.core.automation.internal.module.handler.TimerModuleHandlerFactory)"
        )
        scheduler_field = timer_factory.class.java_class.declared_field(:scheduler)
        scheduler_field.accessible = true
        previous_scheduler = scheduler_field.get(timer_factory)
        client_env = request.fetch("env").dup
        if request.fetch("ruby_engine", "jruby") != "jruby"
          # The client may use CRuby, but embedded engines must use the server's JRuby gems.
          ruby_variables = %w[GEM_HOME GEM_PATH RUBYOPT]
          ruby_variables.each { |key| client_env.delete(key) }
          client_env.merge!(ENV.to_h.slice(*ruby_variables))
        end
        context = java.util.HashMap.new(
          "framework" => OpenHAB::OSGi.bundle,
          "scheduler" => previous_scheduler.instance_variable_get(:@scheduler),
          "stdin" => input.fileno,
          "stdout" => output.fileno,
          "stderr" => error.fileno,
          "env" => java.util.HashMap.new(client_env),
          "cwd" => request.fetch("cwd", Dir.pwd),
          "args" => request.fetch("args").drop(1).to_java(:string),
          "command" => request.fetch("args").first,
          "tty" => request.fetch("tty", false)
        )
        @context = context
        control = Thread.new do
          while (signal = client.gets)
            next unless %w[INT QUIT TERM].include?(signal.chomp)

            context.put("signal", signal.chomp)
            context.get("interrupt")&.run
          end
        rescue IOError, SystemCallError
          nil
        end
        runner = File.expand_path("runner.rb", __dir__)
        engine.context.set_attribute(javax.script.ScriptEngine::FILENAME, runner, javax.script.ScriptContext::ENGINE_SCOPE)
        engine.put("thermos_context", context)
        File.open(runner) do |file|
          engine.eval(java.io.InputStreamReader.new(file.to_inputstream, "UTF-8"))
        end
        context.get("status").to_i
      ensure
        control&.kill
        @context = nil
        scheduler_field.set(timer_factory, previous_scheduler) if previous_scheduler
        begin
          factory.dependency_tracker&.remove_tracking(identifier) if identifier
          extensions&.dispose(identifier) if identifier
        ensure
          begin
            engine&.close
          ensure
            previous_properties&.each do |key, value|
              value ? java.lang.System.set_property(key, value) : java.lang.System.clear_property(key)
            end
          end
        end
      end

      def terminate
        @terminating = true
        @context&.put("signal", "TERM")
        @context&.get("interrupt")&.run
        @interrupt.last.write(".")
      rescue IOError, SystemCallError
        nil
      end

      def print_exception(stream, error)
        stream.puts error.full_message
        stream.flush
      end
    end
  end
end
