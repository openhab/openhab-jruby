# frozen_string_literal: true

module OpenHAB
  module Core
    module DTO
      java_import org.openhab.core.thing.link.dto.ItemChannelLinkDTO

      # Adds methods to core openHAB ItemChannelLinkDTO to make it more natural in Ruby
      class ItemChannelLinkDTO
        #
        # @!attribute [r] item_name
        # @return [String] The name of the item that was linked or unlinked.
        #

        #
        # @!attribute [r] item
        # @return [Item] The item that was linked or unlinked
        #
        def item
          EntityLookup.lookup_item(itemName)
        end

        #
        # @!attribute [r] channel_uid
        # @return [Things::ChannelUID] The UID of the channel that was linked or unlinked.
        #
        def channel_uid
          Things::ChannelUID.new(channelUID)
        end
      end
    end
  end
end
