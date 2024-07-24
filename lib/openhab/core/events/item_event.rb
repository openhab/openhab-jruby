# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemEvent

      #
      # Adds methods to core openHAB ItemEvent to make it more natural in Ruby
      #
      class ItemEvent < AbstractEvent
        #
        # @!attribute [r] item
        # @return [Item] The item that triggered this event.
        #
        def item
          EntityLookup.lookup_item(item_name)
        end

        #
        # @!attribute [r] group
        #
        # Returns the group item whose member had triggered this event.
        #
        # This is the equivalent of openHAB's `triggeringGroup`, and it is only available
        # on a member-of-group trigger.
        #
        # @return [Item,nil] The group item whose member had triggered this event.
        #   `nil` when the event wasn't triggered by a member-of-group trigger.
        #
        # @since openHAB 4.0 for file-based rules
        # @since openHAB 4.1 for UI rules
        #
        def group
          triggering_group = inputs&.[]("triggeringGroup") || Core.ui_context&.[](:triggeringGroup)
          Items::Proxy.new(triggering_group) if triggering_group
        end
      end
    end
  end
end
