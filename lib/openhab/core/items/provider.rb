# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      #
      # Provides {Item Items} created in Ruby to openHAB
      #
      class Provider < Core::Provider
        include org.openhab.core.items.ItemProvider

        class << self
          #
          # The Item registry
          #
          # @return [org.openhab.core.items.ItemRegistry]
          #
          def registry
            $ir
          end
        end

        #
        # Remove an item from this provider
        #
        # @param [String] item_name
        # @param [true, false] recursive
        # @return [Item, nil] The removed item, if found.
        #
        def remove(item_name, recursive = false) # rubocop:disable Style/OptionalBooleanParameter matches Java method
          return nil unless @elements.key?(item_name)

          item = super(item_name)
          item.members.each { |member| remove(member.name, true) } if recursive && item.is_a?(GroupItem)
          item
        end

        def initialize
          super(unload_priority: 50)
        end
      end
    end
  end
end
