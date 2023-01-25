# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      #
      # Contains the link between a {Thing Thing's} {Channel Channels} and {Item Items}.
      #
      module Links
        #
        # Provides {Items::Item items} linked to {Channel channels} in Ruby to openHAB.
        #
        class Provider < Core::Provider
          include org.openhab.core.thing.link.ItemChannelLinkProvider

          class << self
            #
            # The ItemChannelLink registry
            #
            # @return [org.openhab.core.thing.link.ItemChannelLinkRegistry]
            #
            def registry
              @registry ||= OSGi.service("org.openhab.core.thing.link.ItemChannelLinkRegistry")
            end

            # @!visibility private
            def link(item, channel, config = {})
              config = org.openhab.core.config.core.Configuration.new(config.transform_keys(&:to_s))
              channel = ChannelUID.new(channel) if channel.is_a?(String)
              channel = channel.uid if channel.is_a?(Channel)
              link = org.openhab.core.thing.link.ItemChannelLink.new(item.name, channel, config)

              current.add(link)
            end
          end

          #
          # Removes all links to a given item.
          #
          # @param [String] item_name
          # @return [Integer] how many links were removed
          #
          def remove_links_for_item(item_name)
            count = 0
            @elements.delete_if do |_k, v|
              next unless v.item_name == item_name

              count += 1
              notify_listeners_about_removed_element(v)
              true
            end
            count
          end
          alias_method :removeLinksForItem, :remove_links_for_item

          #
          # Removes all links to a given thing.
          #
          # @param [ThingUID] thing_uid
          # @return [Integer] how many links were removed
          #
          def remove_links_for_thing(thing_uid)
            count = 0
            @elements.delete_if do |_k, v|
              next unless v.linked_uid.thing_uid == thing_uid

              count += 1
              notify_listeners_about_removed_element(v)
              true
            end
            count
          end
          alias_method :removeLinksForThing, :remove_links_for_thing
        end
      end
    end
  end
end
