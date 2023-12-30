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

        # @deprecated OH3.4 this whole section is not needed in OH4+. Also see Thing#config_eql?
        if Gem::Version.new(Core::VERSION) < Gem::Version.new("4.0.0")
          # @!visibility private
          module ChannelComparable
            # @!visibility private
            # This is only needed in OH3 because it is implemented in OH4 core
            def ==(other)
              return true if equal?(other)
              return false unless other.is_a?(Channel)

              %i[class
                 uid
                 label
                 description
                 kind
                 channel_type_uid
                 configuration
                 properties
                 default_tags
                 auto_update_policy
                 accepted_item_type].all? do |attr|
                send(attr) == other.send(attr)
              end
            end
          end
          org.openhab.core.thing.binding.builder.ChannelBuilder.const_get(:ChannelImpl).prepend(ChannelComparable)
        end
      end
    end
  end
end
