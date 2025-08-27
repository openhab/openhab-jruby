# frozen_string_literal: true

require "singleton"

module OpenHAB
  module RSpec
    module Mocks
      # reimplement to not use a thread
      class OSGiEventManager
        attr_reader :logger

        def initialize(typed_event_factories, typed_event_subscribers)
          @typed_event_factories = typed_event_factories
          @typed_event_subscribers = typed_event_subscribers
          @logger = org.slf4j.LoggerFactory.get_logger("rspec.openhab.core.mocks.event_handler")
        end

        def handle_event(osgi_event)
          type = osgi_event.get_property("type")
          payload = osgi_event.get_property("payload")
          topic = osgi_event.get_property("topic")
          source = osgi_event.get_property("source")

          if type.is_a?(String) && payload.is_a?(String) && topic.is_a?(String)
            handle_event_internal(type, payload, topic, source) unless type.empty? || payload.empty? || topic.empty?
          else
            logger.error("The handled OSGi event is invalid. " \
                         "Expect properties as string named 'type', 'payload', and 'topic'. " \
                         "Received event properties are: #{osgi_event.property_names.inspect}")
          end
        end

        private

        def handle_event_internal(type, payload, topic, source)
          event_factory = @typed_event_factories[type]
          unless event_factory
            # We can't call the block version because this is a native java logger
            logger.debug("Could not find an Event Factory for the event type '#{type}'.")
            return
          end

          event_subscribers = event_subscribers(type)
          return if event_subscribers.empty?

          event = create_event(event_factory, type, payload, topic, source)
          return unless event

          dispatch_event(event_subscribers, event)
        end

        def event_subscribers(event_type)
          event_type_subscribers = @typed_event_subscribers[event_type]
          all_event_type_subscribers = @typed_event_subscribers["ALL"]

          subscribers = java.util.HashSet.new
          subscribers.add_all(event_type_subscribers) if event_type_subscribers
          subscribers.add_all(all_event_type_subscribers) if all_event_type_subscribers
          subscribers
        end

        def create_event(event_factory, type, payload, topic, source)
          event_factory.create_event(type, topic, payload, source)
        rescue Exception => e
          logger.warn("Creation of event failed, because one of the " \
                      "registered event factories has thrown an exception: #{e.inspect}")
          nil
        end

        def dispatch_event(event_subscribers, event)
          event_subscribers.each do |event_subscriber|
            filter = event_subscriber.event_filter
            if filter.nil? || filter.apply(event)
              begin
                event_subscriber.receive(event)
              rescue Exception => e
                logger.warn(
                  "Dispatching/filtering event for subscriber '#{event_subscriber.class}' failed: #{e.inspect}"
                )
              end
            else
              # Changing this to block syntax will cause specs to fail, for some reason.
              logger.trace("Skip event subscriber (#{event_subscriber.class}) because of its filter.")
            end
          end
        end
      end

      class EventAdmin < org.osgi.util.tracker.ServiceTracker
        include org.osgi.service.event.EventAdmin

        def initialize(bundle_context)
          super(bundle_context, "org.osgi.service.event.EventHandler", nil)

          @handlers_matching_all_events = []
          @handlers_matching_topics = Hash.new { |h, k| h[k] = [] }
          open
        end

        def addingService(reference)
          topics = Array(reference.get_property(org.osgi.service.event.EventConstants::EVENT_TOPIC))
          topics = nil if topics.empty? || topics.include?("*")

          service = OSGi.send(:bundle_context).get_service(reference)

          if reference.get_property("component.name") == "org.openhab.core.internal.events.OSGiEventManager"
            # OSGiEventManager will create a ThreadedEventHandler on OSGi activation;
            # we're skipping that, and directly sending to a non-threaded event handler.
            service.class.field_reader :typedEventFactories, :typedEventSubscribers
            service = OSGiEventManager.new(service.typedEventFactories, service.typedEventSubscribers)
          end
          if topics.nil?
            @handlers_matching_all_events << service
          else
            topics.each do |topic|
              @handlers_matching_topics[topic] << service
            end
          end
          service
        end

        def postEvent(event)
          sendEvent(event)
        end

        def sendEvent(event)
          # prevent re-entrancy
          if (pending_events = Thread.current[:event_admin_pending_events])
            pending_events << event
            return
          end

          pending_events = Thread.current[:event_admin_pending_events] = []
          handle_event(event)
          handle_event(pending_events.shift) until pending_events.empty?
          Thread.current[:event_admin_pending_events] = nil
        end

        private

        def handle_event(event)
          @handlers_matching_all_events.each { |h| h.handle_event(event) }
          @handlers_matching_topics[event.topic].each { |h| h.handle_event(event) }
        end
      end
    end
  end
end
