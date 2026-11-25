# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "../env"

module OpenHAB
  module Thermos
    module Client
      class Command
        attr_reader :args, :env

        def self.call(args)
          new(args).call
        end

        def initialize(args)
          @args = args
          @env = Env.new
        end
      end
    end
  end
end
