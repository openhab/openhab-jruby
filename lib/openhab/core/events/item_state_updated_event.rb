# frozen_string_literal: true

require_relative "item_state_event"

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemStateUpdatedEvent

      #
      # {AbstractEvent} sent when an item's state has updated.
      #
      # @since openHAB 4.0
      #
      class ItemStateUpdatedEvent < ItemEvent
        include ItemState

        # @!attribute [r] last_state_update
        #   @return [ZonedDateTime] the time the previous state update occurred
        #   @since openHAB 5.0

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Events::ItemStateUpdatedEvent item=#{item_name} state=#{item_state.inspect}"
          # @deprecated OH4.3 remove respond_to? check when dropping OH 4.3
          s += " last_state_update=#{last_state_update}" if respond_to?(:last_state_update) && last_state_update
          s += " source=#{source.inspect}" if source
          "#{s}>"
        end
      end
    end
  end
end
