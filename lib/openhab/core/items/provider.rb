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
        def remove(item_name, recursive = false) # rubocop:disable Style/OptionalBooleanParameter -- matches Java method
          item = @elements[item_name]
          return nil unless item

          members = (recursive && item.is_a?(GroupItem)) ? item.members.to_a : []
          DSL::Items::Builder::Persistence.remove(item_name)
          super(item_name)
          members.each { |member| remove(member.name, true) }
          item
        end

        # @!visibility private
        def clear
          DSL::Items::Builder::Persistence.remove(*@elements.key_set.to_a)
          super
        end

        private

        def initialize
          super(unload_priority: 50)
        end
      end
    end
  end
end
