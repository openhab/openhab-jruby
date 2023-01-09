# frozen_string_literal: true

require "delegate"

module OpenHAB
  module Core
    module Items
      #
      # Delegates state storage to a Hash providing methods to operate with states
      #
      class StateStorage < SimpleDelegator
        #
        # Create a StateStorage object that stores the states of the given items
        #
        # @param [Item] items A list of items
        #
        # @return [StateStorage] A state storage object
        #
        # @!visibility private
        def self.from_items(*items)
          StateStorage.new($events.store_states(*items.map(&:to_java)).to_h)
        end

        #
        # Restore the stored states of all items
        #
        # @return [void]
        #
        def restore
          $events.restore_states(to_h)
        end

        #
        # Restore states for items that have changed
        #
        # @return [void]
        #
        def restore_changes
          $events.restore_states(select { |item, value| item.state != value })
        end

        #
        # Detect if any items have changed states since being stored
        #
        # @return [true,false] True if any items have changed states, false otherwise
        #
        def changed?
          any? { |item, value| item.state != value }
        end
      end
    end
  end
end
