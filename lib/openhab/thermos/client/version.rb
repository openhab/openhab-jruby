# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "command"
require_relative "../../dsl/version"

module OpenHAB
  module Thermos
    module Client
      class Version < Command
        def self.description = "Print the thermos version."

        def call
          puts "thermos version #{OpenHAB::DSL::VERSION}"
        end
      end
    end
  end
end
