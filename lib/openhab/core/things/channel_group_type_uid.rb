# frozen_string_literal: true

require "forwardable"

require_relative "uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ChannelGroupTypeUID

      #
      # {ChannelGroupTypeUID} represents a unique identifier for a {ChannelGroupType}.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] channel_definitions
      #   (see ChannelGroupType#channel_definitions)
      #
      # @!attribute [r] category
      #   (see ChannelGroupType#category)
      #
      class ChannelGroupTypeUID < UID
        extend Forwardable

        delegate %i[category channel_definitions] => :channel_group_type

        # @!attribute [r] channel_group_type
        # @return [ChannelGroupType]
        def channel_group_type
          ChannelGroupType.registry.get_channel_group_type(self)
        end
      end
    end
  end
end
