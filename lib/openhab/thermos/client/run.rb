# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require "io/nonblock"
require_relative "command"

module OpenHAB
  module Thermos
    module Client
      class Run < Command
        FORWARDED_SIGNALS = %w[INT QUIT TERM WINCH].select do |signal|
          Signal.list.key?(signal) && !(signal == "QUIT" && RUBY_ENGINE == "jruby")
        end.freeze
        attr_reader :server

        def log(message) = env.log("[client] #{message}")

        def call
          connect
          version = read_server_line(Thermos.connect_timeout)&.chomp
          raise ClientError, "Error connecting to the thermos server" unless version
          if version != env.version
            raise ClientError, "Version mismatch: thermos client #{env.version}, server #{version}. " \
                               "Stop the server and restart it."
          end
          runtime, client = UNIXSocket.pair
          # CRuby creates nonblocking sockets; JRuby's recv_io wrapper assumes a blocking channel.
          client.nonblock = false
          server.send_io client
          send_json(server, "args" => args, "spawn_env" => spawn_env, "reset_env" => reset_env)
          raise CommandNotFound, "Unknown command: #{args.first}" unless read_server_line(Thermos.connect_timeout)

          run_command(runtime)
        ensure
          client&.close unless client&.closed?
          runtime&.close unless runtime&.closed?
          server&.close
        end

        def connect
          @server = UNIXSocket.open(env.socket_name)
        rescue Errno::ENOENT, Errno::ECONNRESET, Errno::ECONNREFUSED, IOError => e
          # JRuby reports a refused UNIX socket connection as IOError rather than Errno::ECONNREFUSED.
          raise if e.is_a?(IOError) && !e.message.start_with?("Connection refused")

          boot_server
          @server = UNIXSocket.open(env.socket_name)
        end

        def boot_server
          unless env.server_running?
            FileUtils.rm_f(env.socket_path)
            pid = Process.spawn(env.server_environment,
                                *env.server_command,
                                out: File::NULL,
                                err: env.log_file,
                                chdir: env.project_root.to_s)
          end
          deadline = Time.now + Thermos.boot_timeout
          until env.socket_path.exist?
            if pid && (result = Process.waitpid2(pid, Process::WNOHANG))
              raise ClientError,
                    "thermos server exited with status #{result.last.exitstatus}; see #{env.log_file.path}"
            end
            raise ClientError, "Starting the thermos server timed out after #{Thermos.boot_timeout} seconds" if
              Time.now > deadline

            sleep 0.1
          end
          Process.detach(pid) if pid
        end

        def reset_env = ENV.slice(*Thermos.reset_on_env)
        def spawn_env = Thermos.spawn_on_env.to_h { |key| [key, ENV[key]] }

        def read_server_line(timeout)
          raise ClientError, "Timed out connecting to the thermos server" unless server.wait_readable(timeout)

          server.gets
        end

        def run_command(runtime)
          runtime.send_io $stdout.to_io
          runtime.send_io $stderr.to_io
          runtime.send_io $stdin.to_io
          send_json(runtime,
                    "args" => args,
                    "env" => ENV.to_h,
                    "cwd" => Dir.pwd,
                    "ruby_engine" => RUBY_ENGINE,
                    "tty" => $stdout.tty?)
          ready = runtime.gets
          raise ClientError, "The thermos runtime failed to start; see #{env.log_file.path}" unless ready

          exit 1 unless ready.chomp == "0"

          raise ClientError, "The thermos runtime disconnected" unless runtime.gets

          # Keep the transferred endpoint open until completion: closing a JRuby UNIXSocket
          # also shuts down its duplicates in the receiving process.
          forward_signals(runtime)
          status = runtime.gets
          raise ClientError, "The thermos runtime exited without a status" if status.to_s.strip.empty?

          exit Integer(status)
        ensure
          @signal_handlers&.each { |signal, handler| Signal.trap(signal, handler) }
        end

        def forward_signals(runtime)
          @signal_handlers = FORWARDED_SIGNALS.to_h do |signal|
            handler = Signal.trap(signal) do
              runtime.puts(signal)
            rescue IOError, SystemCallError
              nil
            end
            [signal, handler]
          end
        end

        def send_json(socket, data)
          json = JSON.dump(data)
          socket.puts(json.bytesize)
          socket.write(json)
        end
      end
    end
  end
end
