# frozen_string_literal: true

require_relative "trigger"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Creates channel triggers
        #
        class Channel < Trigger
          # @return [String] A channel event trigger
          CHANNEL_EVENT = "core.ChannelEventTrigger"

          #
          # Get an enumerator over the product of the channels and things and map them to a channel id
          # @param [Object] channels to iterate over
          # @param [Object] thing to combine with channels and iterate over
          # @return [Enumerable] enumerable channel ids to trigger on
          def self.channels(channels:, thing:)
            logger.trace { "Creating Channel/Thing Pairs for channels #{channels.inspect} and things #{thing.inspect}" }
            channels.flatten.product([thing].flatten)
                    .map { |channel_thing| channel_id(*channel_thing) }
          end

          #
          # Get a channel id from a channel and thing
          # @param [Object] channel part of channel id, get UID if object is a Channel
          # @param [Object] thing part of channel id, get UID if object is a Thing
          #
          def self.channel_id(channel, thing)
            channel = channel.uid if channel.is_a?(org.openhab.core.thing.Channel)
            thing = thing.uid if thing.is_a?(Core::Things::Thing)
            [thing, channel].compact.join(":")
          end

          #
          # Create a trigger for a channel
          #
          # @param [String] channel to look for triggers
          # @param [String] trigger specific channel trigger to match
          # @param [Object] attach object to be attached to the trigger
          #
          #
          def trigger(channel:, trigger:, attach:)
            config = { "channelUID" => channel }
            config["event"] = trigger.to_s unless trigger.nil?
            logger.trace { "Creating Channel Trigger for channels #{channel.inspect} and config #{config.inspect}" }
            append_trigger(type: CHANNEL_EVENT, config:, attach:)
          end
        end
      end
    end
  end
end
