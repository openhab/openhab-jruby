# frozen_string_literal: true

require_relative "../ui/component_builder"

module OpenHAB
  module DSL
    # Build MainUI pages using nested component blocks.
    module Pages
      # Entry point for {Core::Pages::Registry#build pages.build}. Uses the same block and explicit builder styles as
      # the sitemap builder.
      class Builder < UI::BlockEvaluator
        # @!visibility private
        def initialize(builder_proxy, update:)
          super(builder_proxy)
          @update = update
        end

        # Create a page with an explicit root component type. Additional keyword arguments configure the page, including
        # its label and sidebar visibility.
        #
        # @param uid [String] Unique page identifier
        # @param component [String] Root component type; defaults to a layout page
        # @param tags [Array<String>] Root component tags
        # @param config [Hash] Configuration with exact MainUI key names
        # @raise [ArgumentError] If another provider owns the UID, or updates are disabled
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {PageBuilder PageBuilder}. With an explicit block argument, or when an enclosing block supplies one, the
        #   block retains its surrounding `self`.
        # @yieldparam builder [PageBuilder] The page builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def page(uid, component: "oh-layout-page", tags: [], config: {}, **, &)
          build_page(PageBuilder, uid, component, tags:, config:, **, &)
        end

        private

        def build_page(builder_class, uid, component, tags:, config:, **, &)
          uid = uid.to_s
          raise ArgumentError, "Page UID must not be empty" if uid.empty?

          provider = Core::Pages::Provider.instance
          existing = Core::Pages::Provider.registry.get(uid)
          raise ArgumentError, "Page #{uid} is owned by another provider" if existing && !provider.get(uid)
          raise ArgumentError, "Page #{uid} already exists" if existing && !@update

          builder = builder_class.new(component, @builder_proxy, uid:, tags:, config:, **)
          builder.evaluate(&)
          result = builder.build
          if existing
            provider.update(result)
          else
            provider.add(result)
          end
          result
        end
      end

      # Generic page context with shared component helpers. Layout helper blocks reuse their page builder class to
      # construct ordinary components.
      class PageBuilder < UI::ComponentBuilder
        # @!visibility private
        def initialize(type, builder_proxy, uid: nil, tags: [], **)
          @uid = uid
          @tags = tags
          super(type, builder_proxy, **)
        end

        # @!visibility private
        def build
          return super unless @uid

          page = org.openhab.core.ui.components.RootUIComponent.new(@uid, @type)
          page.add_tags(@tags.map(&:to_s).to_java(java.lang.String))
          page.update_timestamp
          build_component(page)
        end
      end
    end
  end
end

require_relative "layout_page_builder"

require_relative "map_page_builder"

require_relative "plan_page_builder"

require_relative "chart_page_builder"

require_relative "tabs_page_builder"

require_relative "page_helpers"
