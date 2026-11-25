# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  # Preloads openHAB and runs commands in isolated JRuby ScriptEngines.
  module Thermos
    class << self
      # Context for the current ScriptEngine, or nil outside a command engine.
      # @return [Hash, nil]
      # @!visibility private
      attr_accessor :context
    end
  end
end
