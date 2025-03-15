# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.Channel

      #
      # {Channel} is a part of a {Thing} that represents a functionality of it.
      # Therefore {Item Items} can be linked a to a channel.
      #
      # @!attribute [r] item
      #   (see ChannelUID#item)
      #
      # @!attribute [r] items
      #   (see ChannelUID#items)
      #
      # @!attribute [r] thing
      #   (see ChannelUID#thing)
      #
      # @!attribute [r] uid
      #   @return [ChannelUID]
      #
      # @!attribute [r] channel_type_uid
      #   @return [ChannelTypeUID]
      #
      class Channel
        extend Forwardable

        delegate %i[item items thing] => :uid

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::Channel #{uid}"
          r += " #{label.inspect}" if label
          r += " description=#{description.inspect}" if description
          r += " kind=#{kind.inspect}"
          r += " channel_type_uid=#{channel_type_uid.inspect}" if channel_type_uid
          r += " configuration=#{configuration.properties.to_h}" unless configuration.properties.empty?
          r += " properties=#{properties.to_h}" unless properties.empty?
          r += " default_tags=#{default_tags.to_a}" unless default_tags.empty?
          r += " auto_update_policy=#{auto_update_policy}" if auto_update_policy
          r += " accepted_item_type=#{accepted_item_type}" if accepted_item_type
          "#{r}>"
        end

        # @!attribute [r] channel_type
        # @return [ChannelType]
        def channel_type
          ChannelType.registry.get_channel_type(channel_type_uid)
        end

        # @return [String]
        def to_s
          uid.to_s
        end

        # @!attribute item_name [r]
        # Return the name of the item this channel is linked to. If a channel is linked to more than one item,
        # this method only returns the first item.
        #
        # @return [String, nil]
        def item_name
          item_names.first
        end

        # @!attribute item_names [r]
        # Return the names of all of the items this channel is linked to.
        #
        # @return [Array<String>]
        def item_names
          Things::Links::Provider.registry.get_linked_item_names(uid)
        end

        # @!attribute item [r]
        # Return the item this channel is linked to. If a channel is linked to more than one item,
        # this method only returns the first item.
        #
        # @return [Items::Item, nil]
        def item
          items.first
        end

        # @!attribute items [r]
        # Return all of the items this channel is linked to.
        #
        # @return [Array<Items::Item>]
        def items
          Things::Links::Provider.registry.get_linked_items(uid).map { |item| Items::Proxy.new(item) }
        end

        #
        # @!attribute links [r]
        # Returns all of the channel's links (items and link configurations).
        #
        # @return [Items::ItemChannelLinks] An array of ItemChannelLink or an empty array
        #
        # @example Get the configuration of the first link
        #   things["mqtt:topic:livingroom-light"].channel["power"].links.first.configuration
        #
        # @example Remove all managed links
        #   things["mqtt:topic:livingroom-light"].channel["power"].links.clear
        #
        # @see link
        # @see unlink
        #
        def links
          Items::ItemChannelLinks.new(uid, Things::Links::Provider.registry.get_links(uid))
        end

        #
        # @return [ItemChannelLink, nil]
        #
        # @overload link
        #   Returns the channel's link. If an channel is linked to more than one item,
        #   this method only returns the first link.
        #
        #   @return [Things::ItemChannelLink, nil]
        #
        # @overload link(item, config = {})
        #
        #   Links the channel to an item.
        #
        #   @param [String, Items::Item] item The item to link to.
        #   @param [Hash] config The configuration for the link.
        #
        #   @return [Things::ItemChannelLink] The created link.
        #
        #   @example Link a channel to an item
        #     things["mqtt:topic:livingroom-light"].channels["power"].link(LivingRoom_Light_Power)
        #
        #   @example Specify a link configuration
        #     things["mqtt:topic:outdoor-thermometer"].channels["temperature"].link(
        #       High_Temperature_Alert,
        #       profile: "system:hysteresis",
        #       lower: "29 °C",
        #       upper: "30 °C")
        #
        #   @see links
        #   @see unlink
        #
        def link(item = nil, config = nil)
          return Things::Links::Provider.registry.get_links(uid).first if item.nil? && config.nil?

          config ||= {}
          Core::Things::Links::Provider.create_link(item, self, config).tap do |new_link|
            provider = Core::Things::Links::Provider.current
            if !(current_link = provider.get(new_link.uid))
              provider.add(new_link)
            elsif current_link.configuration != config
              provider.update(new_link)
            end
          end
        end

        #
        # Removes a link to an item from managed link providers.
        #
        # @param [String, Items::Item] item The item to remove the link to.
        #
        # @return [Things::ItemChannelLink, nil] The removed link, if found.
        # @raise [FrozenError] if the link is not managed by a managed link provider.
        #
        # @see link
        # @see links
        #
        def unlink(item)
          link_to_delete = Things::Links::Provider.create_link(item, self, {})
          provider = Things::Links::Provider.registry.provider_for(link_to_delete.uid)
          unless provider.is_a?(ManagedProvider)
            raise FrozenError,
                  "Cannot remove the link #{link_to_delete.uid} from non-managed provider #{provider.inspect}"
          end

          provider.remove(link_to_delete.uid)
        end
      end
    end
  end
end
