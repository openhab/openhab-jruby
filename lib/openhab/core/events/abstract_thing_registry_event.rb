# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.thing.events.AbstractThingRegistryEvent,
                  org.openhab.core.thing.events.ThingAddedEvent,
                  org.openhab.core.thing.events.ThingUpdatedEvent,
                  org.openhab.core.thing.events.ThingRemovedEvent

      #
      # The {AbstractEvent} sent when a {Things::Thing Thing} is added,
      # updated, or removed from its registry.
      #
      #
      # @!attribute [r] thing
      #   @return [DTO::AbstractThingDTO] The thing that triggered this event.
      #
      class AbstractThingRegistryEvent < AbstractEvent; end

      #
      # The {AbstractEvent} sent with a
      # {DSL::Rules::BuilderDSL#thing_added thing_added trigger}.
      #
      class ThingAddedEvent < AbstractThingRegistryEvent; end

      #
      # The {AbstractEvent} sent with a
      # {DSL::Rules::BuilderDSL#thing_updated thing_updated trigger}.
      #
      class ThingUpdatedEvent < AbstractThingRegistryEvent; end

      #
      # The {AbstractEvent} sent with a
      # {DSL::Rules::BuilderDSL#thing_removed thing_removed trigger}.
      #
      class ThingRemovedEvent < AbstractThingRegistryEvent; end
    end
  end
end
