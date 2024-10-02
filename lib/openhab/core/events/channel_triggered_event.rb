# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.thing.events.ChannelTriggeredEvent

      #
      # {AbstractEvent} sent when a channel triggers.
      #
      class ChannelTriggeredEvent < AbstractEvent
        extend Forwardable

        # @!attribute [r] channel_uid
        # @return [Things::ChannelUID] The UID of the {Things::Channel Channel} that triggered this event.
        alias_method :channel_uid, :get_channel

        # @!attribute [r] channel
        # @return [Things::Channel, nil] The channel that triggered this event.

        # @!attribute [r] thing
        # @return [Things::Thing, nil] The thing that triggered this event.
        def_delegators :channel_uid, :thing, :channel

        # @!attribute [r] event
        # @return [String] The event data

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Events::ChannelTriggeredEvent channel=#{channel} event=#{event.inspect}"
          s += " source=#{source.inspect}" if source
          "#{s}>"
        end
      end
    end
  end
end
