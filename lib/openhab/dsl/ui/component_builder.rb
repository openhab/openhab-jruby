# frozen_string_literal: true

require_relative "components"
require_relative "block_evaluation"

module OpenHAB
  module DSL
    # Shared component-tree infrastructure for MainUI root components.
    module UI
      # Evaluates nested DSL blocks using the same proxy semantics as sitemaps.
      # @!visibility private
      class BlockEvaluator
        include Core::EntityLookup
        include BlockEvaluation

        self.create_dummy_items = true

        def initialize(builder_proxy)
          @builder_proxy = builder_proxy
        end

        private

        def component_config(config, values)
          config.transform_keys(&:to_s).merge(values.compact)
        end

        def grouped_config(name, value, keys)
          return {} if value.nil?

          unless value.is_a?(Hash)
            raise ArgumentError, "#{name} must be a Hash of options" unless keys.key?(:value)

            return { keys.fetch(:value) => value }
          end

          value.each_with_object({}) do |(key, option), result|
            key = key.to_sym if key.is_a?(String)
            unless keys.key?(key)
              raise ArgumentError, "Unknown #{name} option #{key.inspect}; expected #{keys.keys.join(", ")}"
            end

            result[keys.fetch(key)] = option unless option.nil?
          end
        end

        # EntityLookup permits dummy item references. Component names from another context must still fail, even when
        # called without arguments.
        def method_missing(method, ...)
          raise NoMethodError, "#{method} is unavailable in this MainUI context" if Components.helper?(method)

          super
        end

        def respond_to_missing?(method, *)
          return false if Components.helper?(method)

          super
        end
      end

      # Builds a MainUI component and its named slots. Configuration keyword names use snake_case; explicit config keys
      # retain their spelling. Nested hashes also retain their keys. MainUI expression strings are passed through
      # unchanged.
      class ComponentBuilder < BlockEvaluator
        include Components::System
        include Components::Cards
        include Components::ListItems
        include Components::Cells
        include Components::Home

        # @!visibility private
        def self.component_builder
          ComponentBuilder
        end

        # @!visibility private
        def initialize(type, builder_proxy, config: {}, **kwargs)
          super(builder_proxy)
          @type = type.to_s
          @config = config.transform_keys(&:to_s).merge(kwargs.transform_keys { |key| camelize(key) })
          @slots = { "default" => [] }
          @slot = "default"
          @explicit_slot = false
        end

        # Add a component to the current slot. Supports built-in, Framework7, and custom widgets. Additional keyword
        # arguments configure the component; snake_case keys become camelCase. The child has only the shared helper
        # categories, regardless of its component name or parent builder.
        #
        # @param type [String] Component name, such as "oh-button" or "widget:light_card"
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [ComponentBuilder] The component builder
        # @return [ComponentBuilder]
        def component(type, config: {}, **, &)
          add_component(ComponentBuilder, type, config:, **, &)
        end
        alias_method :c, :component

        # Add a personal widget by UID, automatically prefixing its component name with `widget:`. Configuration and
        # child blocks behave like {#component component}, with shared helpers available inside the block.
        #
        # @see #component
        #
        # @example
        #   widget "light_card", config: { "light_item" => LivingRoomLight }
        #
        # @param uid [String] Widget UID without the `widget:` prefix
        # @param config [Hash] Configuration with exact widget property names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [ComponentBuilder] The component builder
        # @return [ComponentBuilder]
        def widget(uid, config: {}, **, &)
          component("widget:#{uid}", config:, **, &)
        end

        # Add children to a named slot, appending on repeated calls. Slot names retain their spelling (for example
        # "xAxis").
        #
        # @example
        #   chart do
        #     slot "xAxis" do
        #       time_axis
        #     end
        #     slot "series" do
        #       time_series item: Temperature
        #     end
        #   end
        #
        # @example Keep the surrounding Ruby context
        #   slot "series" do |builder|
        #     builder.time_series item: Temperature
        #   end
        #
        # @param name [String, Symbol] MainUI slot name
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [ComponentBuilder] The component builder
        # @return [Object] The result of the block
        def slot(name, &)
          previous = @slot
          previous_explicit_slot = @explicit_slot
          @slot = name.to_s
          @explicit_slot = true
          @slots[@slot] ||= []
          evaluate(&)
        ensure
          @slot = previous
          @explicit_slot = previous_explicit_slot
        end

        # @!visibility private
        def build
          build_component(org.openhab.core.ui.components.UIComponent.new(@type))
        end

        private

        def helper_component(type, config:, &)
          add_component(self.class.component_builder, type, config:, &)
        end

        def add_component(builder_class, type, config: {}, **, &)
          child = builder_class.new(type, @builder_proxy, config:, **)
          child.evaluate(&)
          @slots.fetch(@slot) << child
          child
        end

        def camelize(key)
          key.to_s.gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
        end

        def build_component(component)
          component.config = java_value(@config)
          @slots.each do |name, children|
            target = component.add_slot(name)
            children.each { |child| target.add(child.build) }
          end
          component
        end

        def java_value(value)
          case value
          when Hash
            value.to_h { |key, child| [key.to_s, java_value(child)] }
          when Array
            value.map { |child| java_value(child) }
          when Core::Items::Item
            value.name
          when Symbol
            value.to_s
          else
            value
          end
        end
      end
    end
  end
end
