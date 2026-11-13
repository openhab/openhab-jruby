# frozen_string_literal: true

require_relative "../ui/component_builder"
require_relative "properties_builder"

module OpenHAB
  module DSL
    # Define reusable MainUI widgets and their configurable properties.
    module Widgets
      # Entry point for {Core::Widgets::Registry#build widgets.build}.
      class Builder < UI::BlockEvaluator
        # @!visibility private
        def initialize(builder_proxy, update:)
          super(builder_proxy)
          @update = update
        end

        # Define a reusable widget with exactly one root component. The UID is used in `widget:<uid>` references.
        #
        # @see https://www.openhab.org/docs/ui/personal-widgets
        #
        # @param uid [String] Unique widget identifier
        # @param tags [Array<String>] Widget tags
        # @raise [ArgumentError] If the UID is empty, another provider owns it, or updates are disabled
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {WidgetBuilder WidgetBuilder}. With an explicit block argument, or when an enclosing block supplies one,
        #   the block retains its surrounding `self`.
        # @yieldparam builder [WidgetBuilder] The widget builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def widget(uid, tags: [], &)
          uid = uid.to_s
          raise ArgumentError, "Widget UID must not be empty" if uid.empty?

          provider = Core::Widgets::Provider.instance
          existing = Core::Widgets::Provider.registry.get(uid)
          raise ArgumentError, "Widget #{uid} is owned by another provider" if existing && !provider.get(uid)
          raise ArgumentError, "Widget #{uid} already exists" if existing && !@update

          builder = WidgetBuilder.new(uid, @builder_proxy, tags:)
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

      # Collect a widget's root component and property declarations. The root can be any built-in helper or a generic
      # {UI::ComponentBuilder#component component} / {UI::ComponentBuilder#c c} call, including another personal widget.
      class WidgetBuilder < UI::ComponentBuilder
        # @!visibility private
        def initialize(uid, builder_proxy, tags:)
          super("widget", builder_proxy)
          @uid = uid
          @tags = tags
          @properties_builder = nil
        end

        # Declare configurable widget properties using {ConfigDescription::Builder#parameter parameter} and
        # {PropertiesBuilder#group group}. Multiple `props` blocks append declarations.
        #
        # @example
        #   props do
        #     parameter :item, :text, label: "Light", context: "item", required: true
        #     group :appearance, label: "Appearance" do
        #       parameter :title, :text, label: "Title", default: "Light"
        #     end
        #   end
        #
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {PropertiesBuilder PropertiesBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [PropertiesBuilder] The property builder
        # @return [Object, nil] The block result, or nil when no block is given
        def props(&)
          properties_builder.evaluate(&)
        end

        # @!visibility private
        def build
          unless @slots.keys == ["default"] && @slots.fetch("default").size == 1
            raise ArgumentError, "Widget #{@uid} must define exactly one root component; declare slots inside that root"
          end

          root = @slots.fetch("default").first.build
          widget = org.openhab.core.ui.components.RootUIComponent.new(@uid, root.component)
          widget.config = root.config
          widget.slots = root.slots
          widget.props = properties_builder.build
          widget.add_tags(@tags.map(&:to_s).to_java(java.lang.String))
          widget.update_timestamp
          widget
        end

        private

        def properties_builder
          @properties_builder ||= PropertiesBuilder.new(@builder_proxy)
        end
      end
    end
  end
end
