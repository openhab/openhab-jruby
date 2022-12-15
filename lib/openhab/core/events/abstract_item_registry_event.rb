# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.AbstractItemRegistryEvent,
                  org.openhab.core.items.events.ItemAddedEvent,
                  org.openhab.core.items.events.ItemUpdatedEvent,
                  org.openhab.core.items.events.ItemRemovedEvent

      #
      # The {AbstractEvent} sent when an {Item} is added, updated, or removed
      # from its registry.
      #
      # @!attribute [r] item
      #   @return [DTO::ItemDTO] The item that triggered this event.
      #
      class AbstractItemRegistryEvent < AbstractEvent; end

      #
      # The {AbstractEvent} sent with an `item_added` trigger.
      #
      class ItemAddedEvent < AbstractItemRegistryEvent; end

      #
      # The {AbstractEvent} sent with an `item_updated` trigger.
      #
      class ItemUpdatedEvent < AbstractItemRegistryEvent; end

      #
      # The {AbstractEvent} sent with an `item_removed` trigger.
      #
      class ItemRemovedEvent < AbstractItemRegistryEvent; end
    end
  end
end
