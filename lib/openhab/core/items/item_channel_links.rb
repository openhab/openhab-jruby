# frozen_string_literal: true

require "delegate"

module OpenHAB
  module Core
    module Items
      #
      # A wrapper for {Item#links} delegated to Set<{org.openhab.core.thing.link.ItemChannelLink}>.
      #
      # Adds methods for clearing item's links to channels.
      #
      class ItemChannelLinks < SimpleDelegator
        #
        # @param [Item] item The item that the links belong to
        # @param [Set<ItemChannelLink>] links The set of links to delegate to
        #
        # @!visibility private
        def initialize(item, links)
          super(links)
          @item = item
        end

        #
        # Removes all links to channels from managed link providers.
        # @return [self]
        #
        def clear
          Things::Links::Provider.registry.all.each do |link|
            next unless link.item_name == @item.name

            provider = Things::Links::Provider.registry.provider_for(link.uid)
            if provider.is_a?(ManagedProvider)
              provider.remove(link.uid)
            else
              logger.warn("Cannot remove the link #{link.uid} from non-managed provider #{provider.inspect}")
            end
          end
          self
        end
      end
    end
  end
end
