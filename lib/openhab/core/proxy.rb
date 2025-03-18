# frozen_string_literal: true

require "singleton"
require "weakref"

require_relative "script_handling"

module OpenHAB
  module Core
    #
    # Contains the infrastructure necessary to listen for events when objects are
    # added/removed from their registry, and keep Proxy objects up-to-date with
    # their underlying object.
    #
    # The including class must meet a few requirements:
    #  * Have an `EVENTS` constant that is an Array<String> of the events to
    #    listen for
    #  * The _last_ entry in the `EVENTS` array must be the "removed" event
    #  * It must have a sibling class called `Provider`, with a `.registry`
    #    method
    #  * It's parent module, downcased and with trailing "s" stripped, must be
    #    the method name to retrieve an object from one of the incoming events
    #
    # @!visibility private
    #
    module Proxy
      # Error raised when an item is attempted to be accessed, but no longer
      # exists
      class StaleProxyError < RuntimeError
        def initialize(type, uid)
          super("#{type} #{uid} does not currently exist")
        end
      end

      #
      # Registers and listens to openHAB bus events for objects getting
      # added/updated/removed, and updates references from proxy objects
      # to real objects.
      #
      # Proxies are tracked (via a WeakRef), and their underlying object is
      # if it has changed.
      #
      class EventSubscriber
        include Singleton
        include org.openhab.core.events.EventSubscriber

        def initialize
          @proxies = java.util.concurrent.ConcurrentHashMap.new
          @parent_module = Object.const_get(self.class.name.split("::")[0..-3].join("::"), false)
          object_type = @parent_module.name.split("::").last[0...-1]
          @object_type = object_type.downcase.to_sym
          @type = @parent_module.const_get(object_type, false)

          @event_types = @parent_module::Proxy::EVENTS
          @uid_method = @parent_module::Proxy::UID_METHOD
          @uid_type = @parent_module::Proxy::UID_TYPE
          @registry = @parent_module::Provider.registry
          @registration = OSGi.register_service(self)
          ScriptHandling.script_unloaded { @registration.unregister }
        end

        #
        # @!attribute [r] subscribed_event_types
        # @return [Set<String>]
        #
        def subscribed_event_types
          @event_types.to_set
        end

        # @return [org.openhab.core.events.EventFilter, nil]
        def event_filter
          nil
        end

        #
        # @param [Events::AbstractEvent] event
        # @return [void]
        #
        def receive(event)
          uid = event.__send__(@object_type).__send__(@uid_method)
          uid = @uid_type.new(uid) unless @uid_type == String

          @proxies.compute_if_present(uid) do |_, proxy_ref|
            object = @registry.get(uid) unless event.class.simple_name == @event_types.last
            proxy = resolve_ref(proxy_ref)
            next nil unless proxy

            proxy.__setobj__(object)
            proxy_ref
          end
        end

        #
        # Get or create a Proxy for the given raw openHAB object.
        #
        def fetch(object)
          result = nil

          uid = if object.is_a?(@type)
                  object.__send__(@uid_method)
                else
                  object
                end
          @proxies.compute(uid) do |_k, proxy_ref|
            result = resolve_ref(proxy_ref)
            proxy_ref = nil unless result
            result ||= yield

            proxy_ref || WeakRef.new(result)
          end

          result
        end

        private

        def resolve_ref(proxy_ref)
          proxy_ref.__getobj__ if proxy_ref&.weakref_alive?
        rescue WeakRef::RefError
          nil
        end
      end

      # @!visibility private
      module ClassMethods
        # Intercepts calls to create new proxies, and returns the already
        # existing (and tracked) proxy if it exists. Otherwise it does create
        # a new instance of Proxy.
        def new(object)
          self::EventSubscriber.instance.fetch(object) { super }
        end
      end

      # @!visibility private
      def self.included(klass)
        klass.singleton_class.prepend(ClassMethods)
        # define a sub-class of EventSubscriber as a child class of the including class
        klass.const_set(:EventSubscriber, Class.new(EventSubscriber))
        parent_module = Object.const_get(klass.name.split("::")[0..-2].join("::"), false)
        object_type = parent_module.name.split("::").last[0...-1].to_sym
        klass.const_set(:Type, parent_module.const_get(object_type, false))
      end

      # @!visibility private
      def to_java
        __getobj__
      end

      KERNEL_CLASS = ::Kernel.instance_method(:class)
      KERNEL_IVAR_SET = ::Kernel.instance_method(:instance_variable_set)
      private_constant :KERNEL_CLASS, :KERNEL_IVAR_SET

      # @!visibility private

      def initialize(target)
        @klass = KERNEL_CLASS.bind_call(self)

        if target.is_a?(@klass::Type)
          super
          KERNEL_IVAR_SET.bind_call(self, :"@#{@klass::UID_METHOD}", target&.__send__(@klass::UID_METHOD))
        else
          # dummy items; we were just passed the item name
          super(nil)
          KERNEL_IVAR_SET.bind_call(self, :"@#{@klass::UID_METHOD}", target)
        end
      end

      # @!visibility private
      def __setobj__(target)
        @target = target
      end

      # @!visibility private
      def __getobj__
        @target
      end

      # overwrite these methods to handle "dummy" items:
      # if it's a dummy item, and the method exists on Item,
      # raise a StaleProxyError when you try to call it.
      # if it doesn't exist on item, just let it raise NoMethodError
      # as usual
      # @!visibility private
      def method_missing(method, ...)
        target = __getobj__
        if target.nil? && @klass::Type.method_defined?(method)
          __raise__ StaleProxyError.new(@klass.name.split("::")[-2][0...-1], __send__(@klass::UID_METHOD))
        end

        super

        # do _not_ attempt to inline the rest of Delegator#method_missing.
        # see spec/openhab/core/items/proxy_spec.rb for the result
      end

      # @!visibility private
      def respond_to_missing?(method, include_private)
        target = __getobj__
        return true if target.nil? && @klass::Type.method_defined?(method)

        r = target_respond_to?(target, method, include_private)
        if r && include_private && !target_respond_to?(target, method, false)
          warn "delegator does not forward private method ##{method}", uplevel: 3
          return false
        end
        r
      end

      # @!visibility private
      def respond_to?(method, include_private = false) # rubocop:disable Style/OptionalBooleanParameter
        target = __getobj__
        return true if target.nil? && @klass::Type.method_defined?(method)

        target_respond_to?(target, method, include_private) || super
      end

      #
      # Need to check if `self` _or_ the delegate is an instance of the
      # given class
      #
      # So that {#==} can work
      #
      # @return [true, false]
      #
      # @!visibility private
      def instance_of?(klass)
        __getobj__.instance_of?(klass) || super
      end

      #
      # Check if delegates are equal for comparison
      #
      # Otherwise items can't be used in Java maps
      #
      # @return [true, false]
      #
      # @!visibility private
      def ==(other)
        return __getobj__ == other.__getobj__ if other.instance_of?(@klass)

        super
      end

      #
      # Non equality comparison
      #
      # @return [true, false]
      #
      # @!visibility private
      def !=(other)
        !(self == other) # rubocop:disable Style/InverseMethods
      end

      # @return [String]
      def to_s
        target = __getobj__
        return __send__(@klass::UID_METHOD) if target.nil?

        target.to_s
      end

      # @return [String]
      def inspect
        target = __getobj__
        return target.inspect unless target.nil?

        "#<#{self.class.name} #{__send__(@klass::UID_METHOD)}>"
      end

      #
      # Supports inspect from IRB when we're a dummy
      #
      # @return [void]
      # @!visibility private
      def pretty_print(printer)
        target = __getobj__
        return target.pretty_print(printer) unless target.nil?

        printer.text(inspect)
      end
    end
  end
end
