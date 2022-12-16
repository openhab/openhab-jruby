# frozen_string_literal: true

require_relative "triggers/cron/cron"

module OpenHAB
  module DSL
    module Rules
      # Contains helper methods for inferring a rule name from its triggers
      # @!visibility private
      module NameInference
        # Trigger Type UIDs that we know how to generate a name for
        KNOWN_TRIGGER_TYPES = [
          "core.ChannelEventTrigger",
          "core.GenericEventTrigger",
          "core.GroupCommandTrigger",
          "core.GroupStateChangeTrigger",
          "core.GroupStateUpdateTrigger",
          "core.ItemCommandTrigger",
          "core.ItemStateChangeTrigger",
          "core.ItemStateUpdateTrigger",
          "core.SystemStartlevelTrigger",
          Triggers::Cron::CRON_TRIGGER_MODULE_ID
        ].freeze
        private_constant :KNOWN_TRIGGER_TYPES

        class << self
          # get the block's source location, and simplify to a simple filename
          def infer_rule_id_from_block(block)
            file = File.basename(block.source_location.first)
            "#{file}:#{block.source_location.last}"
          end

          # formulate a readable rule name such as "TestSwitch received command ON" if possible
          def infer_rule_name(config)
            known_triggers, unknown_triggers = config.triggers.partition do |t|
              KNOWN_TRIGGER_TYPES.include?(t.type_uid)
            end
            return nil unless unknown_triggers.empty?

            cron_triggers = known_triggers.select { |t| t.type_uid == "jsr223.jruby.CronTrigger" }
            ruby_every_triggers = config.ruby_triggers.select { |t| t.first == :every }

            # makes sure there aren't any true cron triggers cause we can't format them
            return nil unless cron_triggers.length == ruby_every_triggers.length
            return nil unless config.ruby_triggers.length == 1

            infer_rule_name_from_trigger(*config.ruby_triggers.first)
          end

          private

          # formulate a readable rule name from a single trigger if possible
          def infer_rule_name_from_trigger(trigger, items = nil, kwargs = {})
            case trigger
            when :every
              infer_rule_name_from_every_trigger(items, **kwargs)
            when :channel
              infer_rule_name_from_channel_trigger(items, **kwargs)
            when :changed, :updated, :received_command
              infer_rule_name_from_item_trigger(trigger, items, kwargs)
            when :channel_linked, :channel_unlinked
              infer_rule_name_from_channel_link_trigger(trigger)
            when :item_added, :item_removed, :item_updated
              infer_rule_name_from_item_registry_trigger(trigger)
            when :thing_added, :thing_removed, :thing_updated
              infer_rule_name_from_thing_trigger(trigger)
            when :on_start
              infer_rule_name_from_on_start_trigger(items)
            end
          end

          # formulate a readable rule name from an item-type trigger
          def infer_rule_name_from_item_trigger(trigger, items, kwargs)
            kwargs.delete(:command) if kwargs[:command] == [nil]
            return unless items.length <= 3 &&
                          (kwargs.keys - %i[from to command duration]).empty?
            return if kwargs.values_at(:from, :to, :command).compact.any? do |v|
              next false if v.is_a?(Array) && v.length <= 4 # arbitrary length
              next false if v.is_a?(Range)

              v.is_a?(Proc) || v.is_a?(Enumerable)
            end

            trigger_name = trigger.to_s.tr("_", " ")
            item_names = items.map do |item|
              if item.is_a?(GroupItem::Members)
                "#{item.group.name}.members"
              else
                item.name
              end
            end
            name = "#{format_beginning_of_sentence_array(item_names)} #{trigger_name}"

            name += " from #{format_inspected_array(kwargs[:from])}" if kwargs[:from]
            name += " to #{format_inspected_array(kwargs[:to])}" if kwargs[:to]
            name += " #{format_inspected_array(kwargs[:command])}" if kwargs[:command]
            name += " for #{kwargs[:duration]}" if kwargs[:duration]
            name.freeze
          end

          # formulate a readable rule name from an every-style cron trigger
          def infer_rule_name_from_every_trigger(value, at:)
            name = "Every #{value}"
            name += " at #{at}" if at
            name
          end

          # formulate a readable rule name from a channel trigger
          def infer_rule_name_from_channel_trigger(channels, triggers:)
            triggers = [] if triggers == [nil]
            name = "#{format_beginning_of_sentence_array(channels)} triggered"
            name += " #{format_inspected_array(triggers)}" unless triggers.empty?
            name
          end

          # formulate a readable rule name from a channel link trigger
          def infer_rule_name_from_channel_link_trigger(trigger)
            (trigger == :channel_linked) ? "Channel linked to item" : "Channel unlinked from item"
          end

          # formulate a readable rule name from an item added/updated/remove trigger
          def infer_rule_name_from_item_registry_trigger(trigger)
            {
              item_added: "Item added",
              item_updated: "Item updated",
              item_removed: "Item removed"
            }[trigger]
          end

          # formulate a readable rule name from a thing added/updated/remove trigger
          def infer_rule_name_from_thing_trigger(trigger)
            {
              thing_added: "Thing Added",
              thing_updated: "Thing updated",
              thing_removed: "Thing removed"
            }[trigger]
          end

          # formulate a readable rule name from an on_start trigger
          def infer_rule_name_from_on_start_trigger(levels)
            levels = levels.map { |level| "#{level} (#{start_level_description(level)})" }
            levels = format_array(levels)
            "System Start Level reached #{levels}"
          end

          def start_level_description(level)
            klass = org.openhab.core.service.StartLevelService.java_class
            start_level_type = klass.declared_field("STARTLEVEL_OSGI").type
            klass.declared_fields
                 .select { |field| field.type == start_level_type && field.name.start_with?("STARTLEVEL_") }
                 .find { |field| field.get_int(klass) == level }
                 .name.split("_", 2).last.downcase
          end

          # format an array of words that will be the beginning of a sentence
          def format_beginning_of_sentence_array(array)
            result = format_array(array)
            if array.length > 2
              result = result.dup
              result[0] = "A"
              result.freeze
            end
            result
          end

          # format an array of items that need to be inspected individually
          def format_inspected_array(array)
            return array.inspect if array.is_a?(Range)

            array = [array] unless array.is_a?(Array)
            format_array(array.map(&:inspect))
          end

          # format an array of words in a friendly way
          def format_array(array)
            return array[0] if array.length == 1
            return "#{array[0]} or #{array[1]}" if array.length == 2

            "#{array[0..-2].join(", ")}, or #{array[-1]}"
          end
        end
      end
    end
  end
end
