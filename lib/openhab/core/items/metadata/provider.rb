# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      module Metadata
        #
        # Provides metadata created in Ruby to openHAB
        #
        class Provider < Core::Provider
          include org.openhab.core.items.ManagedMetadataProvider

          class << self
            #
            # The Metadata registry
            #
            # @return [org.openhab.core.items.MetadataRegistry]
            #
            def registry
              @registry ||= OSGi.service("org.openhab.core.items.MetadataRegistry")
            end
          end

          # see Hash#javaify
          registry.managed_provider.get.class.field_reader :storage
          registry.managed_provider.get.storage.class.field_reader :entityMapper

          #
          # Removes all metadata of a given item.
          #
          # @param [String] item_name
          # @return [void]
          #
          def remove_item_metadata(item_name)
            @elements.delete_if do |_k, v|
              next unless v.uid.item_name == item_name

              notify_listeners_about_removed_element(v)
              true
            end
            nil
          end
          alias_method :removeItemMetadata, :remove_item_metadata
        end
      end
    end
  end
end
