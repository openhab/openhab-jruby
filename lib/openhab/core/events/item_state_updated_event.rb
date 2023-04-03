# frozen_string_literal: true

require_relative "item_state_event"

module OpenHAB
  module Core
    module Events
      begin
        java_import org.openhab.core.items.events.ItemStateUpdatedEvent

        #
        # {AbstractEvent} sent when an item's state has updated.
        #
        class ItemStateUpdatedEvent < ItemEvent
          include ItemState
        end
      rescue NameError
        # @deprecated OH3.4 OH3 will raise an error ItemStateUpdatedEvent is only in OH4
      end
    end
  end
end
