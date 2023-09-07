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

        #
        # Returns the event payload as a Hash.
        #
        # @return [Hash, nil] The payload object parsed by JSON. The keys are symbolized.
        #   `nil` when the payload is empty.
        #
        def payload
          require "json"
          @payload ||= JSON.parse(get_payload, symbolize_names: true) unless get_payload.empty?
        end
      end
    end
  end
end
