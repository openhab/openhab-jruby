# frozen_string_literal: true

require "singleton"
require_relative "provider"

module OpenHAB
  module Core
    module Widgets
      # Access reusable MainUI widgets and enter the widget builder DSL.
      class Registry
        include LazyArray
        include Singleton

        # @param uid [String] Widget UID
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

        # Create widgets, replacing existing widgets owned by this script by default. Widgets owned by another provider
        # cannot be replaced.
        #
        # @example
        #   widgets.build do
        #     widget "light_card" do
        #       props do
        #         parameter :item, :text, label: "Light", context: "item", required: true
        #       end
        #       toggle_card item: "=props.item"
        #     end
        #   end
        #
        # @param update [true, false] Whether to update existing script-owned widgets
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {DSL::Widgets::Builder Builder}. With an explicit block argument, or when an enclosing block supplies one,
        #   the block retains its surrounding `self`.
        # @yieldparam builder [DSL::Widgets::Builder] The widget builder
        # @return [Object] The result of the block
        def build(update: true, &block)
          proxy = SimpleDelegator.new(nil) if block.arity == 1
          builder = DSL::Widgets::Builder.new(proxy, update:)
          builder.evaluate(&block)
        end

        # Remove a widget owned by this script.
        #
        # @param widget [String, org.openhab.core.ui.components.RootUIComponent]
        # @raise [ArgumentError] If the widget is not owned by this script
        # @return [org.openhab.core.ui.components.RootUIComponent] The removed widget
        def remove(widget)
          uid = widget.respond_to?(:uid) ? widget.uid : widget.to_s
          Provider.instance.remove(uid) || raise(ArgumentError, "Cannot remove widget #{uid}: not owned by this script")
        end
      end
    end
  end
end
