# frozen_string_literal: true

if RUBY_ENGINE == "jruby"
  require "java"
  require "tmpdir"
  require "timeout"
  require "io/nonblock"

  RSpec.describe "Thermos runner IO" do
    # Fresh addon engines must load the project Bundler before running the probe.
    let(:engine_timeout) { 20 }

    it "reads a line before EOF and leaves the original descriptors open after engine shutdown" do
      with_runner('puts "READ: " + $stdin.gets.chomp') do |close_engine, context, worker, input, output|
        input.last.write("hello 🌏\n")
        expect(Timeout.timeout(engine_timeout) { output.first.gets }).to eq "READ: hello 🌏\n"
        expect(worker.join(engine_timeout)).not_to be_nil
        worker.value
        expect(context.get("status")).to eq 0
        close_engine.call

        input.last.write("still open\n")
        expect(input.first.gets).to eq "still open\n"
        expect(input.first.nonblock?).to be false
        output.last.write("still writable\n")
        expect(output.first.gets).to eq "still writable\n"
      end
    end

    it "interrupts a blocked read without waiting for input or EOF" do
      code = <<~RUBY
        current = Thread.current
        Thread.new { sleep 0.1; current.raise(Interrupt) }
        puts "READY"
        $stdin.gets
      RUBY
      with_runner(code) do |_close_engine, context, worker, _input, output|
        expect(Timeout.timeout(engine_timeout) { output.first.gets }).to eq "READY\n"
        expect(worker.join(engine_timeout)).not_to be_nil
        worker.value
        expect(context.get("status")).to eq 130
      end
    end

    it "cancels a request disconnected before the command starts and restores stdin flags" do
      with_runner('raise "command must not run"', signal: "TERM") do |_close_engine, context, worker, input|
        expect(worker.join(engine_timeout)).not_to be_nil
        worker.value
        expect(context.get("status")).to eq 143
        expect(input.first.nonblock?).to be false
      end
    end

    it "uses the runtime's Bundler instead of the addon's default" do
      require "bundler"
      Dir.mktmpdir("thermos-default-bundler") do |directory|
        FileUtils.mkdir_p(File.join(directory, "bundler"))
        File.write(File.join(directory, "bundler/setup.rb"), 'raise "incompatible default Bundler loaded"')
        with_runner('puts "BUNDLER: " + Bundler::VERSION',
                    default_load_path: directory) do |_, context, worker, _, output|
          expect(Timeout.timeout(engine_timeout) { output.first.gets }).to eq "BUNDLER: #{Bundler::VERSION}\n"
          expect(worker.join(engine_timeout)).not_to be_nil
          worker.value
          expect(context.get("status")).to eq 0
        end
      end
    end

    def with_runner(code, signal: nil, default_load_path: nil)
      Dir.mktmpdir("thermos-runner") do |directory|
        gemfile = File.join(directory, "Gemfile")
        File.write(gemfile, "")
        input = IO.pipe
        output = IO.pipe
        error = IO.pipe
        output.last.sync = true
        env = ENV.to_h.merge("BUNDLE_GEMFILE" => gemfile, "BUNDLE_FROZEN" => "false", "BUNDLE_DEPLOYMENT" => "false")
        env.delete("BUNDLE_LOCKFILE")
        env.delete("RUBYOPT")
        context = java.util.HashMap.new(
          "bundler_lib" => Gem.loaded_specs["bundler"]&.full_require_paths&.first,
          "stdin" => input.first.fileno,
          "stdout" => output.last.fileno,
          "stderr" => error.last.fileno,
          "env" => java.util.HashMap.new(env),
          "cwd" => directory,
          "args" => [].to_java(:string),
          "command" => "io-probe",
          "tty" => false
        )
        context.put("signal", signal) if signal
        scope_property = "org.jruby.embed.localcontext.scope"
        previous_scope = java.lang.System.get_property(scope_property)
        java.lang.System.set_property(scope_property, "singlethread")
        engine = if defined?(OpenHAB::Thermos.context) && OpenHAB::Thermos.context
                   factory = OpenHAB::OSGi.service(
                     "org.openhab.core.automation.module.script.ScriptEngineFactory",
                     filter: "(service.pid=org.openhab.automation.jrubyscripting)"
                   )
                   factory.create_script_engine("application/x-ruby")
                 else
                   javax.script.ScriptEngineManager.new.get_engine_by_name("jruby")
                 end
        commands = File.expand_path("../../../../lib/openhab/thermos/commands", __dir__)
        closed = false
        close_engine = lambda do
          next if closed

          closed = true
          engine.close
        end
        # rubocop:disable-next Style/DocumentDynamicEvalDefinition
        engine.eval("$LOAD_PATH.unshift(#{default_load_path.dump})") if default_load_path
        # Define the IO probe in the engine that will load the runner.
        engine.eval(<<~RUBY) # rubocop:disable Style/DocumentDynamicEvalDefinition
          require #{commands.dump}
          command = Object.new
          def command.call
            #{code}
          end
          OpenHAB::Thermos.register_command("io-probe", command)
        RUBY
        runner = File.expand_path("../../../../lib/openhab/thermos/runner.rb", __dir__)
        engine.context.set_attribute(javax.script.ScriptEngine::FILENAME, runner, javax.script.ScriptContext::ENGINE_SCOPE)
        engine.put("thermos_context", context)
        worker = Thread.new do
          File.open(runner) { |file| engine.eval(java.io.InputStreamReader.new(file.to_inputstream, "UTF-8")) }
        end
        yield close_engine, context, worker, input, output
      ensure
        input&.last&.close unless input&.last&.closed?
        worker&.join(2)
        worker&.kill
        close_engine&.call
        if previous_scope
          java.lang.System.set_property(scope_property, previous_scope)
        elsif scope_property
          java.lang.System.clear_property(scope_property)
        end
        [input, output, error].compact.flatten.each { |stream| stream.close unless stream.closed? }
      end
    end
  end
end
