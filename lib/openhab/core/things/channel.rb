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

        # @return [String]
        def to_s
          uid.to_s
        end
      end
    end
  end
end
