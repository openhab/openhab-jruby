# frozen_string_literal: true

require "singleton"

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

          # Extends the openHAB watch service to watch directories
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

            # Invoked by java super class when an watch event occurs
            # @param [String] _event ignored
            # @param [StandardWatchEventKind] kind NIO watch event kind
            # @param [java.nio.file.Path] path that had an event
            def processWatchEvent(_event, kind, path)
              @block.call(Events::WatchEvent.new(EVENT_TO_SYMBOL[kind], Pathname.new(path.to_s)))
            end
          end
          # rubocop:enable Naming/MethodName

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
              @watcher&.deactivate
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
