# frozen_string_literal: true

require "singleton"

module OpenHAB
  module Core
    # @interface
    java_import org.openhab.core.common.registry.ManagedProvider

    # @!visibility private
    module ManagedProvider
      # Maps actual element types to the symbol used in Thread.local[:openhab_providers]
      TYPE_TO_PROVIDER_TYPE = {
        org.openhab.core.items.Item.java_class => :items,
        org.openhab.core.items.Metadata.java_class => :metadata,
        org.openhab.core.automation.Rule.java_class => :rules,
        org.openhab.core.thing.Thing.java_class => :things,
        org.openhab.core.thing.link.ItemChannelLink.java_class => :links
      }.freeze
      private_constant :TYPE_TO_PROVIDER_TYPE

      # @return [Symbol, nil]
      def type
        java_class.generic_ancestors.each do |klass|
          next unless klass.respond_to?(:raw_type)
          next unless klass.raw_type == org.openhab.core.common.registry.Provider.java_class

          type_arg = klass.actual_type_arguments.first
          next unless type_arg.is_a?(java.lang.Class)
          next unless klass.actual_type_arguments.first.is_a?(java.lang.Class)

          return TYPE_TO_PROVIDER_TYPE[type_arg]
        end
        nil
      end
    end

    # @abstract
    class Provider < org.openhab.core.common.registry.AbstractProvider
      include org.openhab.core.common.registry.ManagedProvider
      include Enumerable
      include Singleton
      public_class_method :new

      # Known supported provider types
      # @return [Array<Symbol>]
      KNOWN_TYPES = %i[items metadata things links].freeze

      class << self
        #
        # Determines the current provider that should be used to create elements belonging to this registry.
        #
        # @param [org.openhab.core.common.registry.Provider, Proc, :persistent, :transient, nil] preferred_provider
        #   An optional preferred provider to use. Can be one of several types:
        #    * An explicit instance of {org.openhab.core.common.registry.ManagedProvider ManagedProvider}
        #    * A Proc, which can calculate the preferred provider based on whatever conditions it wants,
        #      and then is further processed as this parameter.
        #    * `:persistent`, meaning the default {org.openhab.core.common.registry.ManagedProvider ManagedProvider}
        #      for this registry. Managed providers persist their objects to JSON, and will survive after the
        #      Ruby script is unloaded. This is where objects you configure with MainUI are stored. You should
        #      use this provider when you're creating something in response to a one-time event.
        #    * `:transient`, meaning a {org.openhab.core.common.registry.ManagedProvider ManagedProvider} that
        #      will remove all of its contents when the Ruby script is unloaded. You should use this if you're
        #      generating objects dynamically, either based on some sort of other configuration, or simply
        #      hard coded and you're using Ruby as a more expressive way to define things than a `.items` or
        #      `.things` file. If you _don't_ use this provider for something such as metadata, then you
        #      may have issues such as metadata still showing up even though you're no longer creating items
        #      with it anymore.
        #    * `nil`, meaning to fall back to the current thread setting. See {OpenHAB::DSL.provider}.
        #      If there is no thread setting (or the thread setting was Proc that returned `nil`),
        #      it defaults to `:transient`.
        # @return [org.openhab.core.common.registry.Provider]
        #
        def current(preferred_provider = nil, element = nil)
          preferred_provider ||= Thread.current[:openhab_providers]&.[](type)
          if preferred_provider.is_a?(Proc)
            preferred_provider = if preferred_provider.arity.zero? || element.nil?
                                   preferred_provider.call
                                 else
                                   preferred_provider.call(element)
                                 end
          end

          case preferred_provider
          when nil, :transient
            instance
          when :persistent
            registry.managed_provider.get
          when org.openhab.core.common.registry.ManagedProvider
            preferred_provider
          else
            raise ArgumentError, "#{preferred_provider.inspect} is not a ManagedProvider"
          end
        end

        # @abstract
        # @!attribute [r] registry
        #
        # The registry that this provider provides elements for.
        #
        # @return [org.openhab.core.common.registry.Registry]
        #
        def registry
          raise NotImplementedError
        end

        #
        # Creates a new instance of a provider, registers it, sets it as the
        # default for the thread, calls the block, and then unregisters it.
        #
        # @param [true, false] thread_provider Set this new provider as the default for the thread
        # @yieldparam [Provider] provider The provider
        # @return [Object] The result of the block
        #
        # @!visibility private
        def new(thread_provider: true)
          unless @singleton__instance__.nil? || block_given?
            raise NoMethodError,
                  "private method `new' called for #{self}:Class"
          end

          r = provider = super()
          if block_given?
            if thread_provider
              DSL.provider(provider) do
                r = yield provider
              end
            else
              r = yield provider
            end
            provider.unregister
          end
          r
        end

        # @!attribute [r] type
        # @!visibility private
        # @return [Symbol]
        #
        def type
          name.split("::")[-2].downcase.to_sym
        end
      end

      # @!visibility private
      def each(&block)
        @elements.each_value(&block)
      end

      # @return [String]
      def inspect
        "#<#{self.class.name}:#{object_id}>"
      end

      # @!visibility private
      def add(element)
        @elements.compute(element.uid) do |_k, old_element|
          raise ArgumentError, "Element #{element.uid} already exists, and cannot be added again" if old_element

          element
        end
        notify_listeners_about_added_element(element)
        element
      end

      #
      # Get an element from this provider
      #
      # @param [Object] key The proper key type for the elements in this provider.
      # @return [Object]
      #
      def [](key)
        @elements[key]
      end
      alias_method :get, :[]

      #
      # Get all elements in this provider
      #
      # @return [Array<Object>]
      #
      def all
        @elements.values
      end
      alias_method :getAll, :all

      #
      # Remove an element from this provider
      #
      # @return [Object, nil] the removed element
      #
      # @!visibility private
      #
      def remove(key)
        @elements.delete(key)&.tap do |element|
          notify_listeners_about_removed_element(element)
        end
      end

      # @return [Object, nil] the previous version of the element
      # @!visibility private
      #
      def update(element)
        old = nil
        @elements.compute(element.uid) do |_k, old_element|
          raise ArgumentError, "Element #{element.uid} does not exist to update" unless old_element

          old = old_element
          element
        end
        notify_listeners_about_updated_element(old, element)
        old
      end

      # @!visibility private
      def unregister
        self.class.registry.remove_provider(self)
      end

      private

      def initialize(unload_priority: nil)
        super()
        @elements = java.util.concurrent.ConcurrentHashMap.new
        self.class.registry.add_provider(self)
        ScriptHandling.script_unloaded(priority: unload_priority) { unregister }
      end
    end
  end
end
