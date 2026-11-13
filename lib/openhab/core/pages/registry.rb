# frozen_string_literal: true

require "singleton"
require_relative "provider"

module OpenHAB
  module Core
    module Pages
      # Access MainUI pages and enter the page builder DSL.
      class Registry
        include LazyArray
        include Singleton

        # @param uid [String] Page UID
        # @return [org.openhab.core.ui.components.RootUIComponent, nil]
        def [](uid)
          Provider.registry.get(uid.to_s)
        end
        alias_method :include?, :[]
        alias_method :key?, :[]

        # @return [Array<org.openhab.core.ui.components.RootUIComponent>]
        def to_a
          Provider.registry.all.to_a
        end

        # Create pages, replacing existing pages owned by this script by default. Pages owned by another provider cannot
        # be replaced.
        #
        # @example
        #   pages.build do
        #     layout_page "home", label: "My Home" do
        #       block do
        #         grid_row do
        #           grid_col { toggle_card item: LivingRoomLight }
        #         end
        #       end
        #     end
        #   end
        #
        # @param update [true, false] Whether to update existing script-owned pages
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {DSL::Pages::Builder Builder}. With an explicit block argument, or when an enclosing block supplies one, the
        #   block retains its surrounding `self`.
        # @yieldparam builder [DSL::Pages::Builder] The page builder
        # @return [Object] The result of the block
        def build(update: true, &block)
          proxy = SimpleDelegator.new(nil) if block.arity == 1
          builder = DSL::Pages::Builder.new(proxy, update:)
          builder.evaluate(&block)
        end

        # Remove a page owned by this script.
        #
        # @param page [String, org.openhab.core.ui.components.RootUIComponent]
        # @raise [ArgumentError] If the page is not owned by this script
        # @return [org.openhab.core.ui.components.RootUIComponent] The removed page
        def remove(page)
          uid = page.respond_to?(:uid) ? page.uid : page.to_s
          Provider.instance.remove(uid) || raise(ArgumentError, "Cannot remove page #{uid}: not owned by this script")
        end
      end
    end
  end
end
