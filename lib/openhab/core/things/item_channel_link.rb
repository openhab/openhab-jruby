# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.link.ItemChannelLink

      #
      # Represents the link between an {Item} and a {Thing Thing's}
      # {Channel}.
      #
      # @!attribute [r] thing
      #   @return [Thing]
      #
      # @!attribute [r] channel_uid
      #   @return [ChannelUID]
      #
      class ItemChannelLink
        extend Forwardable

        def_delegator :linked_uid, :thing

        # @!attribute [r] item
        # @return [Item]
        def item
          DSL.items[item_name]
        end

        # @!attribute [r] channel
        # @return [Channel]
        def channel
          DSL.things[linked_uid.thing_uid].channels[linked_uid.id]
        end

        alias_method :channel_uid, :linked_uid
      end
    end
  end
end
