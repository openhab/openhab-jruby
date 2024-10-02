# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.thing.events.ThingStatusInfoChangedEvent,
                  org.openhab.core.thing.events.ThingStatusInfoEvent

      #
      # The {AbstractEvent} sent when a {Things::Thing Thing's} status has changed.
      #
      class ThingStatusInfoChangedEvent < AbstractEvent
        # @!attribute [r] uid
        # @return [Things::ThingUID] The UID of the {Things::Thing Thing} that triggered this event.
        alias_method :uid, :get_thing_uid
        # @!attribute [r] was
        # @return [org.openhab.core.thing.ThingStatusInfo] The thing's prior status.
        alias_method :was, :get_old_status_info
        # @!attribute [r] status
        # @return [org.openhab.core.thing.ThingStatusInfo] The thing's status.
        alias_method :status, :status_info

        #
        # @!attribute [r] thing
        # @return [Things::Thing] The thing that triggered this event.
        #
        def thing
          EntityLookup.lookup_thing(uid)
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Events::ThingStatusInfoChangedEvent thing=#{uid} " \
              "status=#{status.inspect} was=#{was.inspect}"
          s += " source=#{source.inspect}" if source
          "#{s}>"
        end
      end

      # The {AbstractEvent} sent when a {Things::Thing}'s status is set.
      class ThingStatusInfoEvent < AbstractEvent
        #
        # @!attribute [r] uid
        # @return [Things::ThingUID] The UID of the {Things::Thing Thing} that triggered this event.
        #
        alias_method :uid, :get_thing_uid
        #
        # @!attribute [r] status
        # @return [org.openhab.core.thing.ThingStatusInfo] The thing's status.
        #
        alias_method :status, :status_info

        #
        # @!attribute [r] thing
        # @return [Things::Thing] The thing that triggered this event.
        #
        def thing
          EntityLookup.lookup_thing(uid)
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Events::ThingStatusInfoEvent thing=#{uid} " \
              "status=#{status.inspect}"
          s += " source=#{source.inspect}" if source
          "#{s}>"
        end
      end
    end
  end
end
