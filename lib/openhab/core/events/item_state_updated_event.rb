# frozen_string_literal: true

require_relative "item_state_event"

module OpenHAB
  module Core
    module Events
      # @deprecated OH3.4 if guard only needed in OH 3.4
      if Gem::Version.new(OpenHAB::Core::VERSION) >= Gem::Version.new("4.0.0")
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
end
