# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "command"

module OpenHAB
  module Thermos
    module Client
      class Status < Command
        def self.description = "Show openHAB background runtime status."

        def call
          if env.server_running?
            puts "openHAB background runtime is running:"
            puts
            print_process env.pid
            runtime_pids.each { |pid| print_process pid }
          else
            puts "openHAB background runtime is not running."
          end
        end

        def print_process(pid)
          puts `ps -p #{pid} -o pid= -o command=`
        end

        def runtime_pids
          candidates = `ps -ax -o ppid= -o pid=`.lines
          candidates.grep(/^(\s+)?#{env.pid} /)
                    .map { |l| l.split.last }
        end
      end
    end
  end
end
