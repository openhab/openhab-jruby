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
            def initialize(path, subdirs, types, &block)
              @types = types.map { |type| STRING_TO_EVENT[type] }
              @block = block
              @subdirs = subdirs
              @path = Pathname.new(path)
              return if path.to_s.start_with?(OpenHAB::Core.config_folder.to_s)

              @custom_watcher = "jrubyscripting-#{SecureRandom.uuid}"
            end

            # Creates a new Watch Service and registers ourself as a listener
            # This isn't an OSGi service, but it's called by {WatchTriggerHandler} below.
            def activate
              java_path = java.nio.file.Path.of(@path.to_s)

              service_name = WatchService::SERVICE_PID
              filter = if @custom_watcher
                         WatchHandler.factory.create_watch_service(@custom_watcher, java_path)
                         logger.trace { "Created a watch service #{@custom_watcher} for #{@path}" }
                         "(name=#{@custom_watcher})"
                       else
                         logger.trace { "Using configWatcher service for #{@path}" }
                         WatchService::CONFIG_WATCHER_FILTER
                       end

              start = Time.now
              sleep 0.1 until (@watch_service = OSGi.service(service_name, filter: filter)) || Time.now - start > 2

              unless @watch_service
                logger.warn("Watch service is not ready in time. #{@path} will not be monitored!")
                return
              end

              @watch_service.register_listener(self, java_path, @subdirs)
              logger.trace { "Registered watch service listener for #{@path} including subdirs: #{@subdirs}" }
            end

            # Unregister ourself as a listener and remove the watch service
            def deactivate
              @watch_service&.unregister_listener(self)
              return unless @custom_watcher

              WatchHandler.factory.remove_watch_service(@custom_watcher)
              logger.trace { "Removed watch service #{@custom_watcher} for #{@path}" }
            end

            # Invoked by the WatchService when a watch event occurs
            # @param [org.openhab.core.service.WatchService.Kind] kind WatchService event kind
            # @param [java.nio.file.Path] path The path that had an event
            def processWatchEvent(kind, path) # rubocop:disable Naming/MethodName
              logger.trace { "processWatchEvent triggered #{path} #{kind} #{@types}" }
              return unless @types.include?(kind)

              # OH4 WatchService feeds us a relative path,
              # but just in case its implementation changes in the future
              path = path.absolute? ? Pathname.new(path.to_s) : @path + path.to_s
              @block.call(Events::WatchEvent.new(EVENT_TO_SYMBOL[kind], path))
            end
          end

          # Implements the openHAB TriggerHandler interface to process Watch Triggers
          class WatchTriggerHandler
            include org.openhab.core.automation.handler.TriggerHandler

            class << self
              #
              # Returns the directory to watch, subdir flag, and glob pattern to use
              #
              # @param [String] path The path provided to the watch trigger which may include glob patterns
              # @param [String] glob The glob pattern provided by the user
              #
              # @return [Array<String,Boolean,String>,nil] An array of directory to watch,
              #   whether to watch in subdirectories, and the glob pattern to use.
              #   Returns nil if the given path doesn't exist all the way to root, e.g. /nonexistent
              #
              def dir_subdir_glob(path, glob)
                pathname = Pathname.new(path)
                return [pathname.dirname.to_s, false, path] if pathname.file?

                dir = find_parent(pathname)
                return unless dir

                # we were given the exact existing directory to watch
                if dir == pathname
                  glob_pathname = Pathname.new(glob)
                  subdirs = recursive_glob?(glob)
                  unless glob_pathname.absolute? || glob.start_with?("**")
                    glob = subdirs ? "**/#{glob}" : "#{path}/#{glob}"
                  end
                  return [path, subdirs, glob]
                end

                if glob != "*" # if it isn't the default glob
                  logger.warn("The provided glob '#{glob}' is ignored because " \
                              "the given path (#{path}) isn't an existing directory, " \
                              "so it is used as the glob pattern")
                end

                relative_glob = pathname.relative_path_from(dir).to_s
                subdir_flag = dir != pathname.dirname || recursive_glob?(relative_glob)
                [dir.to_s, subdir_flag, path]
              end

              # Returns true if string contains glob characters
              def glob?(string)
                unless @regexp
                  # (?<!X) is a negative lookbehind pattern: only match the pattern if it wasn't
                  # preceded with X. In this case we want to match only non escaped glob chars
                  glob_pattern = %w[** * ? [ ] { }].map { |char| Regexp.escape(char) }
                                                   .join("|")
                                                   .then { |pattern| "(?<!\\\\)(#{pattern})" }

                  @regexp = Regexp.new(glob_pattern)
                end
                @regexp.match?(string)
              end

              # Returns true if string contains a recursive glob pattern (** or x/y)
              def recursive_glob?(string)
                /(?<!\\\\)\*\*/.match?(string) || Pathname.new(string).each_filename.to_a.size > 1
              end

              #
              # Find the part of the path that exists on disk.
              #
              # /a/b/c/*/d/*.e -> /a/b/c if it exists
              # /a/b/c/d/e/f -> /a/b/c if /a/b/c directory exists, but /a/b/c/d doesn't exist
              # /a/b/c -> nil if /a doesn't exist
              # / -> /
              #
              # @param [Pathname] pathname The pathname to check
              # @return [Pathname,nil] The leading part of the path name that corresponds to
              #   an existing directory. nil if none was found up until the root directory
              #
              def find_parent(pathname)
                return pathname if pathname.root?

                pathname.ascend { |part| return part if part.directory? && !part.root? }
              end
            end

            # Creates a new WatchTriggerHandler
            # @param [org.openhab.core.automation.Trigger] trigger
            #
            def initialize(trigger)
              @trigger = trigger
              config = trigger.configuration.properties.to_hash.transform_keys(&:to_sym)
              @path, subdirs, glob = self.class.dir_subdir_glob(config[:path], config[:glob])
              logger.trace { "WatchTriggerHandler#initialize path: #{@path}, subdirs: #{subdirs}, glob: #{glob}" }
              unless @path
                logger.warn("Watch error: the given path doesn't exist: '#{@path}'")
                return
              end
              @watcher = Watcher.new(@path, subdirs, config[:types], &watch_event_handler(glob))
              @watcher.activate
              logger.trace { "Created watcher for #{@path} subdirs: #{subdirs}" }
            end

            # Create a lambda to use to invoke rule engine when file watch notification happens
            # @param [String] glob to match for notification events
            #
            # @return [Proc] lambda to execute on notification events
            #
            def watch_event_handler(glob)
              default_fs = java.nio.file.FileSystems.default
              path_matcher = default_fs.get_path_matcher("glob:#{glob}")
              lambda do |watch_event|
                if path_matcher.matches(default_fs.get_path(watch_event.path.to_s))
                  logger.trace do
                    "Received event(#{watch_event}) glob: #{glob}, rule_engine_callback = #{@rule_engine_callback}"
                  end
                  @rule_engine_callback&.triggered(@trigger, { "event" => watch_event })
                else
                  logger.trace { "Event #{watch_event} did not match glob(#{glob})" }
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
              logger.trace { "Deactivating watcher for #{@path}" }
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
