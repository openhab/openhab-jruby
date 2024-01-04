# frozen_string_literal: true

require "forwardable"

require_relative "uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.ChannelUID

      #
      # {ChannelUID} represents a unique identifier for a {Channel}.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] id_without_group
      #   @return [String]
      #
      # @!attribute [r] group_id
      #   @return [String, nil]
      #
      # @!attribute [r] thing_uid
      #   @return [ThingUID]
      #
      class ChannelUID < UID
        # @return [true, false]
        alias_method :in_group?, :is_in_group

        #
        # @attribute [r] thing
        #
        # Return the thing this channel is associated with.
        #
        # @return [Thing, nil]
        #
        def thing
          EntityLookup.lookup_thing(thing_uid)
        end

        # @attribute [r] channel
        #
        # Return the channel object for this channel
        #
        # @return [Channel, nil]
        #
        def channel
          thing.channels[self]
        end

        #
        # @attribute [r] item
        #
        # Return the item if this channel is linked with an item. If a channel is linked to more than one item,
        # this method only returns the first item.
        #
        # @return [Item, nil]
        #
        def item
          items.first
        end

        #
        # @attribute [r] items
        #
        # Returns all of the channel's linked items.
        #
        # @return [Array<Item>] An array of things or an empty array
        #
        def items
          Links::Provider.registry.get_linked_items(self).map { |i| Items::Proxy.new(i) }
        end
      end
    end
  end
end
