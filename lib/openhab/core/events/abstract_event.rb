# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.events.AbstractEvent

      # Add attachments event data.
      class AbstractEvent
        # @return [Object]
        attr_accessor :attachment

        # @return [Hash]
        attr_accessor :inputs

        # @return [String]
        alias_method :inspect, :to_s
      end
    end
  end
end
