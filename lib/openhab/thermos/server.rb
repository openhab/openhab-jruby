# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "env"
require_relative "commands"
require_relative "runtime_manager"
require_relative "process_title_updater"
require_relative "../dsl/version"

module OpenHAB
  module Thermos
    # Coordinates clients and a persistent JRuby/openHAB runtime.
    class Server
      def self.boot(**) = new(**).boot
      attr_reader :env

      def initialize(foreground: false, env: nil)
        @runtime_mutex = Mutex.new
        @clients = {}
        @clients_mutex = Mutex.new
        @foreground = foreground
        @env = env || Env.new(log_file: (foreground && !ENV["THERMOS_SERVER_LOG"]) ? $stdout : nil)
        @pidfile = @env.pidfile_path.open("a")
      end

      def foreground? = @foreground
      def log(message) = env.log("[server] #{message}")

      def boot
        env.require_jruby!
        Thermos.verify_environment
        return unless write_pidfile

        Process.setsid unless foreground?
        IGNORE_SIGNALS.each { |sig| trap(sig, "IGNORE") } unless foreground?
        trap("TERM") { exit }
        trap("INT") { exit } if foreground?
        @title_updater = ProcessTitleUpdater.run do |distance|
          "thermos server | #{env.app_name} | started #{distance} ago"
        end
        redirect_output unless foreground?
        start_server
      ensure
        shutdown
      end

      def start_server
        FileUtils.rm_f(env.socket_path)
        @server = UNIXServer.open(env.socket_name)
        log "started on #{env.socket_name}"
        loop do
          Thread.new(@server.accept) { |client| serve(client) }
        end
      rescue Interrupt
        nil
      end

      def serve(client)
        @clients_mutex.synchronize do
          return if @stopping

          @clients[Thread.current] = client
        end
        client.puts env.version
        runtime_client = client.recv_io(UNIXSocket)
        request = JSON.parse(client.read(client.gets.to_i))
        args, spawn_env, reset_env = request.values_at("args", "spawn_env", "reset_env")
        return unless Thermos.command?(args.first)

        client.puts
        @runtime_mutex.synchronize do
          return if @stopping

          if @runtime && (@runtime.spawn_env != spawn_env || @reset_env != reset_env)
            @runtime.stop
            @runtime = nil
          end
          @reset_env = reset_env
          @runtime ||= RuntimeManager.new(spawn_env || {}, env)
          @runtime.run(runtime_client)
        end
      rescue Errno::EPIPE, Errno::ECONNRESET
        log "client disconnected"
      rescue => e
        log e.full_message
      ensure
        runtime_client&.close unless runtime_client&.closed?
        close_client(client)
        @clients_mutex.synchronize { @clients.delete(Thread.current) }
      end

      def close_client(client)
        client.close
      rescue IOError
        nil
      end

      def write_pidfile
        return unless @pidfile.flock(File::LOCK_EX | File::LOCK_NB)

        @owns_pidfile = true
        @pidfile.truncate(0)
        @pidfile.write("#{Process.pid}\n")
        @pidfile.fsync
        @pidfile
      end

      def shutdown
        return unless @owns_pidfile

        begin
          @server&.close
          clients = @clients_mutex.synchronize do
            @stopping = true
            @clients.dup
          end
          clients.each do |thread, client|
            thread.kill
            close_client(client)
          end
          clients.each_key(&:join)
          @runtime&.stop
        ensure
          @server&.close
          FileUtils.rm_f([env.socket_path, env.pidfile_path])
        end
      ensure
        @title_updater&.kill
        @pidfile.close unless @pidfile.closed?
        @owns_pidfile = false
      end

      # Otherwise a detached server would keep the caller's pipeline open.
      def redirect_output
        [$stdout, $stderr].each { |stream| stream.reopen(env.log_file) }
        $stdin.reopen(File::NULL)
      end
    end
  end
end
