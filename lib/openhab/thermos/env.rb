# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require "fileutils"
require "json"
require "rbconfig"
require "socket"
require "digest/md5"
require "tmpdir"

require_relative "configuration"
require_relative "launcher"

module OpenHAB
  module Thermos
    # Project-local paths and lifecycle operations shared by client commands.
    # @!visibility private
    class Env
      # Allow the runtime's ten-second shutdown grace period plus coordinator cleanup.
      STOP_TIMEOUT = 15 # seconds

      def initialize(root: nil, log_file: nil)
        @project_root = root && Pathname.new(root)
        @log_file = log_file
      end

      def project_root
        @project_root ||= Thermos.project_root_path
      end

      def app_name = project_root.basename.to_s

      def log_file
        @log_file ||= File.new(ENV["THERMOS_SERVER_LOG"] || tmp_path.join("#{project_id}.log"),
                               "a",
                               0o600).tap do |file|
          file.sync = true
        end
      end

      def server_environment = Launcher.new(project_root).environment

      def server_command(foreground: false)
        [*Launcher.new(project_root).command,
         "-I",
         File.expand_path("../..", __dir__),
         "-ropenhab/thermos/server",
         "-e",
         "OpenHAB::Thermos::Server.boot(foreground: #{foreground})"]
      end

      def require_jruby!
        return if RUBY_ENGINE == "jruby"

        raise ClientError, "The openHAB server must be started under JRuby. Retry with JRuby; " \
                           "once the server is running, you can switch to CRuby for the client."
      end

      def version
        OpenHAB::DSL::VERSION
      end

      def tmp_path
        path = Pathname.new(
          ENV["THERMOS_TMP_PATH"] ||
            File.join(ENV["XDG_RUNTIME_DIR"] || Dir.tmpdir, "thermos-#{Process.uid}")
        )
        FileUtils.mkdir_p(path, mode: 0o700) unless path.exist?
        path
      end

      def project_id
        ENV["THERMOS_PROJECT_ID"] || Digest::MD5.hexdigest(project_root.to_s)
      end

      def socket_path
        Pathname.new(ENV["THERMOS_SOCKET"] || tmp_path.join(project_id))
      end

      def socket_name = socket_path.to_s

      def pidfile_path
        Pathname.new(ENV["THERMOS_PIDFILE"] || socket_path.dirname.join("#{socket_path.basename(".*")}.pid"))
      end

      def pid
        value = pidfile_path.read.to_i if pidfile_path.exist?
        value if value&.positive?
      rescue Errno::ENOENT
        # This can happen if the pidfile is removed after we check it
        # exists
      end

      def server_running?
        pidfile = pidfile_path.open("r+")
        !pidfile.flock(File::LOCK_EX | File::LOCK_NB)
      rescue Errno::ENOENT
        false
      ensure
        if pidfile
          pidfile.flock(File::LOCK_UN)
          pidfile.close
        end
      end

      def log(message)
        log_file.puts "[#{Time.now}] [#{Process.pid}] #{message}"
        log_file.flush
      end

      def stop
        return :not_running unless server_running?

        timeout = Time.now + STOP_TIMEOUT

        kill "TERM"

        sleep 0.1 until !server_running? || Time.now >= timeout

        if server_running?
          kill "KILL"
          :killed
        else
          :stopped
        end
      end

      def kill(sig)
        pid = self.pid
        Process.kill(sig, pid) if pid
      rescue Errno::ESRCH
        # already dead
      end
    end
  end
end
