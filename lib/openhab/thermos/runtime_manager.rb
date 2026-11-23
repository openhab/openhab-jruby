# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    # Owns one runtime process; individual commands use ScriptEngines in that process.
    class RuntimeManager
      attr_reader :pid, :child, :spawn_env, :background_env

      def initialize(spawn_env, background_env)
        @spawn_env = spawn_env
        @background_env = background_env
        @mutex = Mutex.new
      end

      def log(message) = background_env.log("[runtime_manager] #{message}")
      def alive? = !@pid.nil?

      def run(client)
        @mutex.synchronize do
          start_child unless alive?
          child.syswrite("R")
          child.send_io client
          raise Errno::EPIPE unless child.gets

          worker = child.gets
          # Retain the forwarded socket until the runtime has finished using its copy.
          raise Errno::EPIPE unless child.gets

          worker&.to_i&.nonzero?
        end
      rescue Errno::ECONNRESET, Errno::EPIPE => e
        log "runtime disconnected: #{e.message}"
        nil
      ensure
        client.close
      end

      def stop
        @stopping = true
        Process.kill("TERM", pid) if pid
        if @waiter && !@waiter.join(10)
          Process.kill("KILL", pid) if pid
          @waiter.join
        end
        child&.close unless child&.closed?
      rescue Errno::ESRCH
        @waiter&.join
      end

      private

      def start_child
        require "securerandom"
        socket_path = background_env.tmp_path.join("runtime-#{SecureRandom.hex(8)}")
        listener = UNIXServer.open(socket_path.to_s)
        # The addon runs in unnamed modules, which also need access to native IO descriptors.
        @pid = Process.spawn(
          spawn_env.merge("THERMOS_ORIGINAL_ENV" => JSON.dump(ORIGINAL_ENV),
                          "THERMOS_MANAGER_SOCKET" => socket_path.to_s),
          RbConfig.ruby,
          "-J--add-opens=java.base/java.io=ALL-UNNAMED",
          "-J--add-opens=java.base/java.nio.channels=ALL-UNNAMED",
          "-J--add-opens=java.base/sun.nio.ch=ALL-UNNAMED",
          "-I",
          File.expand_path("../..", __dir__),
          "-e",
          "require 'openhab/thermos/runtime/boot'",
          in: File::NULL,
          out: background_env.log_file,
          err: background_env.log_file,
          chdir: background_env.project_root.to_s
        )
        started_pid = @pid
        waiter = @waiter = Process.detach(started_pid)
        @monitor = Thermos.failsafe_thread do
          waiter.join
          @pid = nil if @pid == started_pid
        end
        unless listener.wait_readable(Thermos.boot_timeout)
          raise "Runtime failed to connect within #{Thermos.boot_timeout} seconds"
        end

        @child = listener.accept
        raise "Runtime failed to start" unless child.gets
      ensure
        listener&.close
        FileUtils.rm_f(socket_path) if socket_path
      end
    end
  end
end
