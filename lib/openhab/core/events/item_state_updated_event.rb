# frozen_string_literal: true

require_relative "item_state_event"

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemStateUpdatedEvent

      #
      # {AbstractEvent} sent when an item's state has updated.
      #
      class ItemStateUpdatedEvent < ItemEvent
        include ItemState
      end
    end
  end
end
