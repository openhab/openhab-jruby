# frozen_string_literal: true

require "singleton"
require "pathname"
require "securerandom"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Module for watching directories/files
        #
        module WatchHandler
          # Trigger ID for Watch Triggers
          WATCH_TRIGGER_MODULE_ID = "jsr223.jruby.WatchTrigger"

          # WatchService is only available in openHAB4
          def self.factory
            @factory ||= OSGi.service("org.openhab.core.service.WatchServiceFactory")
          end

          # Due to the refactoring in OH4, we need a different watcher implementation
          if WatchHandler.factory
            # A class that implements openHAB4's WatchEventListener
            # and also creates and removes a unique WatchService for each instance
            class Watcher
              # Use full java class name here to satisfy YARD linter
              include org.openhab.core.service.WatchService::WatchEventListener
              java_import org.openhab.core.service.WatchService

              # Hash of event symbols as strings to map to WatchService events
              STRING_TO_EVENT = {
                created: WatchService::Kind::CREATE,
                deleted: WatchService::Kind::DELETE,
                modified: WatchService::Kind::MODIFY
              }.transform_keys(&:to_s).freeze

              # Hash of WatchService event kinds to ruby symbols
              EVENT_TO_SYMBOL = STRING_TO_EVENT.invert.transform_values(&:to_sym).freeze

              # constructor
              def initialize(path, types, &block)
                @types = types.map { |type| STRING_TO_EVENT[type] }
                @block = block
                @path = Pathname.new(path)
                @watcher_name = "jrubyscripting-#{SecureRandom.uuid}"
              end

              # Creates a new Watch Service and registers ourself as a listener
              # This isn't an OSGi service, but it's called by {WatchTriggerHandler} below.
              def activate
                java_path = java.nio.file.Path.of(@path.to_s)
                WatchHandler.factory.create_watch_service(@watcher_name, java_path)
                logger.trace("Created a watch service #{@watcher_name} for #{@path}")

                until (@watch_service = OSGi.service(WatchService::SERVICE_PID, filter: "(name=#{@watcher_name})"))
                  sleep 0.1
                end
                @watch_service.register_listener(self, java_path)
                logger.trace("Registered watch service listener for #{@watcher_name} for #{@path}")
              end

              # Unregister ourself as a listener and remove the watch service
              def deactivate
                @watch_service.unregister_listener(self)
                WatchHandler.factory.remove_watch_service(@watcher_name)
                logger.trace("Removed watch service #{@watcher_name} for #{@path}")
              end

              # Invoked by the WatchService when a watch event occurs
              # @param [org.openhab.core.service.WatchService.Kind] kind WatchService event kind
              # @param [java.nio.file.Path] path that had an event
              def processWatchEvent(kind, path) # rubocop:disable Naming/MethodName
                logger.trace { "processWatchEvent triggered for #{@watcher_name} kind: #{kind} path: #{path}" }
                return unless @types.include?(kind)

                # OH4 WatchService feeds us a relative path,
                # but just in case its implementation changes in the future
                path = if path.absolute?
                         path.to_s
                       else
                         @path + path.to_s
                       end

                @block.call(Events::WatchEvent.new(EVENT_TO_SYMBOL[kind], path, false))
              end
            end
          else
            # @deprecated OH3.4
            #
            # Extends the openHAB3 watch service to watch directories
            #
            # Must match java method name style
            # rubocop:disable Naming/MethodName
            class Watcher < org.openhab.core.service.AbstractWatchService
              java_import java.nio.file.StandardWatchEventKinds

              # Hash of event symbols as strings to map to NIO events
              STRING_TO_EVENT = {
                created: StandardWatchEventKinds::ENTRY_CREATE,
                deleted: StandardWatchEventKinds::ENTRY_DELETE,
                modified: StandardWatchEventKinds::ENTRY_MODIFY
              }.transform_keys(&:to_s).freeze

              # Hash of NIO event kinds to ruby symbols
              EVENT_TO_SYMBOL = STRING_TO_EVENT.invert.transform_values(&:to_sym).freeze

              # Creates a new Watch Service
              def initialize(path, types, &block)
                super(path)
                @types = types.map { |type| STRING_TO_EVENT[type] }
                @block = block
              end

              # Invoked by java super class to get type of events to watch for
              # @param [String] _path ignored
              #
              # @return [Array] array of NIO event kinds
              def getWatchEventKinds(_path)
                @types
              end

              # Invoked by java super class to check if sub directories should be watched
              # @return [false] false
              def watchSubDirectories
                false
              end

              # Invoked by java super class when a watch event occurs
              # @param [String] _event ignored
              # @param [StandardWatchEventKind] kind NIO watch event kind
              # @param [java.nio.file.Path] path that had an event
              def processWatchEvent(_event, kind, path)
                @block.call(Events::WatchEvent.new(EVENT_TO_SYMBOL[kind], Pathname.new(path.to_s)))
              end
            end
            # rubocop:enable Naming/MethodName
          end

          # Implements the openHAB TriggerHandler interface to process Watch Triggers
          class WatchTriggerHandler
            include org.openhab.core.automation.handler.TriggerHandler

            # Creates a new WatchTriggerHandler
            # @param [org.openhab.core.automation.Trigger] trigger
            #
            def initialize(trigger)
              @trigger = trigger
              config = trigger.configuration.properties.to_hash.transform_keys(&:to_sym)
              @path = config[:path]
              @watcher = Watcher.new(@path, config[:types], &watch_event_handler(config[:glob]))
              @watcher.activate
              logger.trace("Created watcher for #{@path}")
            end

            # Create a lambda to use to invoke rule engine when file watch notification happens
            # @param [String] glob to match for notification events
            #
            # @return [Proc] lambda to execute on notification events
            #
            def watch_event_handler(glob)
              lambda do |watch_event|
                if watch_event.path.fnmatch?(glob)
                  logger.trace("Received event(#{watch_event})")
                  @rule_engine_callback&.triggered(@trigger, { "event" => watch_event })
                else
                  logger.trace("Event #{watch_event} did not match glob(#{glob})")
                end
              end
            end

            # Called by openHAB to set the rule engine to invoke when triggered
            def setCallback(callback) # rubocop:disable Naming/MethodName
              @rule_engine_callback = callback
            end

            #
            # Dispose of handler which deactivates watcher
            #
            def dispose
              logger.trace("Deactivating watcher for #{@path}")
              @watcher.deactivate
            end
          end

          # Implements the ScriptedTriggerHandlerFactory interface to create a new Trigger Handler
          class WatchTriggerHandlerFactory
            include Singleton
            include org.openhab.core.automation.module.script.rulesupport.shared.factories.ScriptedTriggerHandlerFactory

            def initialize
              Core.automation_manager.add_trigger_handler(
                WATCH_TRIGGER_MODULE_ID,
                self
              )

              Core.automation_manager.add_trigger_type(org.openhab.core.automation.type.TriggerType.new(
                                                         WATCH_TRIGGER_MODULE_ID,
                                                         nil,
                                                         "A path change event is detected",
                                                         "Triggers when a path change event is detected",
                                                         nil,
                                                         org.openhab.core.automation.Visibility::VISIBLE,
                                                         nil
                                                       ))
              logger.trace("Added watch trigger handler")
            end

            # Invoked by openHAB core to get a trigger handler for the supllied trigger
            # @param [org.openhab.core.automation.Trigger] trigger
            #
            # @return [WatchTriggerHandler] trigger handler for supplied trigger
            def get(trigger)
              WatchTriggerHandler.new(trigger)
            end
          end
        end
      end
    end
  end
end
