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
      end
    end
  end
end
