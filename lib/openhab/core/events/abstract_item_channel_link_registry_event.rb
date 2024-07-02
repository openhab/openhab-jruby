# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.thing.link.events.AbstractItemChannelLinkRegistryEvent,
                  org.openhab.core.thing.link.events.ItemChannelLinkAddedEvent,
                  org.openhab.core.thing.link.events.ItemChannelLinkRemovedEvent

      #
      # The {AbstractEvent} sent when an {Things::ItemChannelLink} is added or removed
      # from its registry.
      #
      # @!attribute [r] link
      #   @return [DTO::ItemChannelLinkDTO] The link that triggered this event.
      #
      class AbstractItemChannelLinkRegistryEvent < AbstractEvent; end

      #
      # The {AbstractEvent} sent with an `channel_linked` trigger.
      #
      class ItemChannelLinkAddedEvent < AbstractItemChannelLinkRegistryEvent; end

      #
      # The {AbstractEvent} sent with an `channel_unlinked` trigger.
      #
      class ItemChannelLinkRemovedEvent < AbstractItemChannelLinkRegistryEvent; end
    end
  end
end
