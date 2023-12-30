# frozen_string_literal: true

require "forwardable"

require_relative "uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ChannelTypeUID

      #
      # {ChannelTypeUID} represents a unique identifier for a {ChannelType}.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] item_type
      #   (see ChannelType#item_type)
      #
      # @!attribute [r] tags
      #   (see ChannelType#tags)
      #
      # @!attribute [r] category
      #   (see ChannelType#category)
      #
      # @!attribute [r] auto_update_policy
      #   (see ChannelType#auto_update_policy)
      #
      class ChannelTypeUID < UID
        extend Forwardable

        # @!method advanced?
        #   @return [true, false]

        delegate %i[item_type
                    tags
                    category
                    auto_update_policy
                    command_description
                    event_description
                    state_description
                    advanced?] => :channel_type

        # @!attribute [r] channel_type
        # @return [ChannelType]
        def channel_type
          ChannelType.registry.get_channel_type(self)
        end
      end
    end
  end
end
