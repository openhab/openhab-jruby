# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "command"

module OpenHAB
  module Thermos
    module Client
      class Stop < Command
        def self.description = "Stop the background runtime for this project."

        def call
          case env.stop
          when :stopped
            puts "openHAB background runtime stopped."
          when :killed
            warn "openHAB background runtime did not stop; killing forcibly."
          when :not_running
            puts "openHAB background runtime is not running"
          end
        end
      end
    end
  end
end
