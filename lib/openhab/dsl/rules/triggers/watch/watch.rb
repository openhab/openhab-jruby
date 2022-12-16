# frozen_string_literal: true

require "openhab/dsl/rules/triggers/trigger"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Creates watch triggers
        #
        class Watch < Trigger
          # Characters in an fnmatch compatible glob
          GLOB_CHARS = ["**", "*", "?", "[", "]", "{", "}"].freeze
          private_constant :GLOB_CHARS

          #
          # Automatically creates globs for supplied paths if necessary
          #
          # @param [Pathname] path to check
          # @param [String] glob
          #
          # @return [Pathname,String] Pathname to watch and glob to match
          #
          def self.glob_for_path(path, glob)
            # Checks if the supplied pathname last element contains a glob char
            if GLOB_CHARS.any? { |char| path.basename.to_s.include? char }
              # Splits the supplied pathname into a glob string and parent path
              [path.basename.to_s, path.parent]
            elsif path.file? || !path.exist?
              # glob string matching end of Pathname and parent path
              ["*/#{path.basename}", path.parent]
            else
              [glob, path]
            end
          end

          #
          # Create a watch trigger based on item type
          #
          # @param [Config] config Rule configuration
          # @param [Object] attach object to be attached to the trigger
          #
          #
          def trigger(config:, attach:)
            WatchHandler::WatchTriggerHandlerFactory.instance # ensure it's registered
            append_trigger(type: WatchHandler::WATCH_TRIGGER_MODULE_ID,
                           config: config,
                           attach: attach)
          end
        end
      end
    end
  end
end
