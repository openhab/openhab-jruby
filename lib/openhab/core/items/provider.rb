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
          DSL::Items::Builder::Persistence.synchronize do
            names = removal_names(item_name, recursive)
            result = nil
            begin
              names.each do |name|
                removed = super(name)
                result = removed if name == item_name
              end
              result
            ensure
              names.reject! { |name| self.class.registry.get(name) }
              DSL::Items::Builder::Persistence.remove(*names)
            end
          end
        end

        # @!visibility private
        def clear
          DSL::Items::Builder::Persistence.synchronize do
            names = @elements.key_set.to_a
            begin
              super
            ensure
              names.reject! { |name| self.class.registry.get(name) }
              DSL::Items::Builder::Persistence.remove(*names)
            end
          end
        end

        private

        def removal_names(item_name, recursive)
          names = {}
          pending = [item_name]
          until pending.empty?
            name = pending.pop
            next if names.key?(name)

            item = @elements[name]
            next unless item

            names[name] = true
            pending.concat(item.members.map(&:name)) if recursive && item.is_a?(GroupItem)
          end
          names.keys
        end

        def initialize
          super(unload_priority: 50)
        end
      end
    end
  end
end
