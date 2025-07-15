# frozen_string_literal: true

require "singleton"

require "openhab/core/entity_lookup"
require "openhab/core/lazy_array"

module OpenHAB
  module Core
    module Items
      #
      # Provides access to all openHAB {Item items}, and acts like an array.
      #
      class Registry
        include LazyArray
        include Singleton

        # Fetches the named item from the the ItemRegistry
        # @param [String] name
        # @return [Item] Item from registry, nil if item missing or requested item is a Group Type
        def [](name)
          EntityLookup.lookup_item(name)
        end

        # Returns true if the given item name exists
        # @param name [String] Item name to check
        # @return [true,false] true if the item exists, false otherwise
        def key?(name)
          !$ir.get(name).nil?
        end
        alias_method :include?, :key?
        # @deprecated
        alias_method :has_key?, :key?

        # Explicit conversion to array
        # @return [Array]
        def to_a
          $ir.items.map { |item| Proxy.new(item) }
        end

        #
        # Enter the Item Builder DSL.
        #
        # @param (see Core::Provider.current)
        # @param update [true, false]  Update existing items with the same name.
        #   When false, an error will be raised if an item with the same name already exists.
        # @yield Block executed in the context of a {DSL::Items::Builder}
        # @return [Object] The return value of the block.
        # @raise [ArgumentError] if an item with the same name already exists and `update` is false.
        # @raise [FrozenError] if `update` is true but the existing item with the same name
        #   wasn't created by the current provider.
        #
        # @see DSL::Items::Builder DSL::Items::Builder for more details and examples
        #
        def build(preferred_provider = nil, update: true, &block)
          DSL::Items::BaseBuilderDSL.new(preferred_provider, update:)
                                    .instance_eval_with_dummy_items(&block)
        end

        #
        # Remove an item.
        #
        # The item must be a managed item (typically created by Ruby or in the UI).
        #
        # Any associated metadata or channel links are also removed.
        #
        # @param [String, Item] item_name
        # @param recursive [true, false] Remove the item's members if it's a group
        # @return [Item, nil] The removed item, if found.
        def remove(item_name, recursive: false)
          item_name = item_name.name if item_name.is_a?(Item)
          provider = Provider.registry.provider_for(item_name)
          unless provider.is_a?(ManagedProvider)
            raise "Cannot remove item #{item_name} from non-managed provider #{provider.inspect}"
          end

          Metadata::Provider.registry.providers.grep(ManagedProvider).each do |managed_provider|
            managed_provider.remove_item_metadata(item_name)
          end

          Things::Links::Provider.registry.providers.grep(ManagedProvider).each do |managed_provider|
            managed_provider.remove_links_for_item(item_name) if managed_provider.respond_to?(:remove_links_for_item)
          end
          provider.remove(item_name, recursive)
        end
      end
    end
  end
end
