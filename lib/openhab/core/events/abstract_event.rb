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

        # @!attribute [r] source
        # @return [String] The component that sent the event.

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

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Events::#{self.class.simple_name} topic=#{topic} payload=#{payload.inspect}"
          s += " source=#{source.inspect}" if source
          "#{s}>"
        end
      end
    end
  end
end
