# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ChannelGroupDefinition

      #
      # {ChannelGroupDefinition} is a part of a {ThingType} that represents a set of channels
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
      # @!attribute [r] channel_group_type_uid
      #   @return [ChannelGroupTypeUID]
      #
      # @!attribute [r] channel_group_type
      #   (see ChannelGroupTypeUID#channel_group_type)
      #
      class ChannelGroupDefinition
        extend Forwardable

        alias_method :channel_group_type_uid, :type_uid

        delegate channel_group_type: :channel_group_type_uid

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::ChannelGroupDefinition #{id}"
          r += " channel_group_type_uid=#{channel_group_type_uid.inspect}"
          r += " #{label.inspect}" if label
          r += " description=#{description.inspect}" if description
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
