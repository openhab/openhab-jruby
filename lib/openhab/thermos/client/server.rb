# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "command"

module OpenHAB
  module Thermos
    module Client
      class Server < Command
        def self.description = "Explicitly start an openHAB runtime in the foreground; --background detaches it."

        def call
          if foreground?
            exec(env.server_environment, *env.server_command(foreground: true)) unless RUBY_ENGINE == "jruby"

            require_relative "../server"
            Thermos::Server.boot(foreground: true)
          else
            Run.new(args).boot_server unless env.server_running?
            Status.call(["status"])
          end
        end

        def foreground?
          !args.include?("--background")
        end
      end
    end
  end
end
