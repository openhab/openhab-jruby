# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.ChannelUID

      #
      # {ChannelUID} represents a unique identifier for {Channel channels}.
      #
      class ChannelUID
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
