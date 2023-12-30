# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ChannelDefinition

      #
      # {ChannelDefinition} is a part of a {ChannelGroupType} that represents a functionality of it.
      # Therefore {Item Items} can be linked a to a channel.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] label
      #   @return [String, nil]
      #
      # @!attribute [r] description
      #   @return [String, nil]
      #
      # @!attribute [r] channel_type_uid
      #   @return [ChannelTypeUID]
      #
      # @!attribute [r] channel_type
      #   (see ChannelTypeUID#channel_type)
      #
      # @!attribute [r] properties
      #   @return [Hash<String, String>]
      #
      class ChannelDefinition
        extend Forwardable

        delegate channel_type: :channel_type_uid

        # @!attribute [r] auto_update_policy
        # @return [:veto, :default, :recommend, nil]
        def auto_update_policy
          get_auto_update_policy&.to_s&.downcase&.to_sym
        end

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::ChannelDefinition #{id}"
          r += " channel_type_uid=#{channel_type_uid.inspect}" if channel_type_uid
          r += " #{label.inspect}" if label
          r += " description=#{description.inspect}" if description
          r += " auto_update_policy=#{auto_update_policy}" if auto_update_policy
          r += " properties=#{properties.to_h}" unless properties.empty?
          "#{r}>"
        end

        # @return [String]
        def to_s
          id.to_s
        end
      end
    end
  end
end
