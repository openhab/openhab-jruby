# frozen_string_literal: true

require_relative "item_state_event"

# @deprecated OH3.4 guard only needed in OH 3.4
return unless OpenHAB::Core.version >= OpenHAB::Core::V4_0

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
      end
    end
  end
end
