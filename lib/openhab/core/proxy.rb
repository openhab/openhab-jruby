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
          @object_type = @parent_module.name.split("::").last.downcase[0..-2].to_sym

          @event_types = @parent_module::Proxy::EVENTS
          @uid_method = @parent_module::Proxy::UID_METHOD
          @registry = @parent_module::Provider.registry
          @registration = OSGi.register_service(self, "event.topics": "openhab/*")
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
          object = @registry.get(uid) unless event.class.simple_name == @event_types.last

          @proxies.compute_if_present(uid) do |_, proxy_ref|
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

          @proxies.compute(object.__send__(@uid_method)) do |_k, proxy_ref|
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
      end

      # @!visibility private
      def to_java
        __getobj__
      end
    end
  end
end
