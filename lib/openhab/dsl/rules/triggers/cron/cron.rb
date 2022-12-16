# frozen_string_literal: true

require "openhab/dsl/rules/triggers/trigger"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Creates cron triggers
        #
        class Cron < Trigger
          # Trigger ID for Cron Triggers
          CRON_TRIGGER_MODULE_ID = "jsr223.jruby.CronTrigger"

          #
          # Returns a default map for cron expressions that fires every second
          # This map is usually updated via merge by other methods to refine cron type triggers.
          #
          # @return [Hash] Map with symbols for :seconds, :minute, :hour, :dom, :month, :dow
          #   configured to fire every second
          #
          CRON_EXPRESSION_MAP =
            {
              second: "*",
              minute: "*",
              hour: "*",
              dom: "?",
              month: "*",
              dow: "?",
              year: "*"
            }.freeze
          private_constant :CRON_EXPRESSION_MAP

          # @return [Hash] Map of days of the week from symbols to to openHAB cron strings
          DAY_OF_WEEK_MAP = {
            monday: "MON",
            tuesday: "TUE",
            wednesday: "WED",
            thursday: "THU",
            friday: "FRI",
            saturday: "SAT",
            sunday: "SUN"
          }.freeze
          private_constant :DAY_OF_WEEK_MAP

          # @return [Hash] Converts the DAY_OF_WEEK_MAP to map used by Cron Expression
          DAY_OF_WEEK_EXPRESSION_MAP = DAY_OF_WEEK_MAP.transform_values { |v| CRON_EXPRESSION_MAP.merge(dow: v) }

          private_constant :DAY_OF_WEEK_EXPRESSION_MAP

          # @return [Hash] Create a set of cron expressions based on different time intervals
          EXPRESSION_MAP = {
            second: CRON_EXPRESSION_MAP,
            minute: CRON_EXPRESSION_MAP.merge(second: "0"),
            hour: CRON_EXPRESSION_MAP.merge(second: "0", minute: "0"),
            day: CRON_EXPRESSION_MAP.merge(second: "0", minute: "0", hour: "0"),
            week: CRON_EXPRESSION_MAP.merge(second: "0", minute: "0", hour: "0", dow: "MON"),
            month: CRON_EXPRESSION_MAP.merge(second: "0", minute: "0", hour: "0", dom: "1"),
            year: CRON_EXPRESSION_MAP.merge(second: "0", minute: "0", hour: "0", dom: "1", month: "1")
          }.merge(DAY_OF_WEEK_EXPRESSION_MAP).freeze

          private_constant :EXPRESSION_MAP

          #
          # Create a cron map from a duration
          #
          # @param [Duration] duration
          # @param [Object] at LocalTime or String representing time of day
          #
          # @return [Hash] map describing cron expression
          #
          def self.from_duration(duration, at)
            raise ArgumentError, '"at" cannot be used with duration' if at

            map_to_cron(duration_to_map(duration))
          end

          #
          # Create a cron map from a MonthDay
          #
          # @param [MonthDay] monthday a {MonthDay} object
          # @param [Object] at LocalTime or String representing time of day
          #
          # @return [Hash] map describing cron expression
          #
          def self.from_monthday(monthday, at)
            expression_map = EXPRESSION_MAP[:day].merge(month: monthday.month_value, dom: monthday.day_of_month)
            expression_map = at_condition(expression_map, at) if at
            map_to_cron(expression_map)
          end

          #
          # Create a cron map from a symbol
          #
          # @param [Symbol] symbol
          # @param [Object] at LocalTime or String representing time of day
          #
          # @return [Hash] map describing cron expression created from symbol
          #
          def self.from_symbol(symbol, at)
            expression_map = EXPRESSION_MAP[symbol]
            expression_map = at_condition(expression_map, at) if at
            map_to_cron(expression_map)
          end

          #
          # Create a cron map from cron elements
          #
          # @param [Hash] fields Cron fields (second, minute, hour, dom, month, dow, year)
          #
          # @return [Hash] map describing cron expression
          #
          def self.from_fields(fields)
            extra_fields = fields.keys - CRON_EXPRESSION_MAP.keys
            unless extra_fields.empty?
              raise ArgumentError,
                    "unknown keyword#{"s" if extra_fields.size > 1}: #{extra_fields.map(&:inspect).join(", ")}"
            end

            fields = fields.transform_values { |value| value.to_s.delete(" ") }
            # find the first expression map that has a field from fields.
            # this ensure more-specific fields get set to 0, not *
            base_key = EXPRESSION_MAP.keys.find { |field, _| fields.key?(field) }
            base_expression = EXPRESSION_MAP[base_key]
            expression_map = base_expression.merge(fields)

            map_to_cron(expression_map)
          end

          #
          # Map cron expression to to cron string
          #
          # @param [Map] map of cron expression
          #
          # @return [String] openHAB cron string
          #
          def self.map_to_cron(map)
            %i[second minute hour dom month dow year].map { |field| map.fetch(field) }.join(" ")
          end

          #
          # Convert a Java Duration to a map for the map_to_cron method
          #
          # @param duration [Duration] The duration object
          #
          # @return [Hash] a map suitable for map_to_cron
          #
          def self.duration_to_map(duration)
            if duration.to_millis_part.zero? && duration.to_nanos_part.zero? && duration.to_days.zero?
              %i[second minute hour].each do |unit|
                to_unit_part = duration.public_send("to_#{unit}s_part")
                next unless to_unit_part.positive?

                to_unit = duration.public_send("to_#{unit}s")
                break unless to_unit_part == to_unit

                return EXPRESSION_MAP[unit].merge(unit => "*/#{to_unit}")
              end
            end
            raise ArgumentError, "Cron Expression not supported for duration: #{duration}"
          end

          #
          # If an at time is provided, parse that and merge the new fields into the expression.
          #
          # @param [<Type>] expression_map <description>
          # @param [<Type>] at_time <description>
          #
          # @return [<Type>] <description>
          #
          def self.at_condition(expression_map, at_time)
            if at_time
              tod = at_time.is_a?(LocalTime) ? at_time : LocalTime.parse(at_time)
              expression_map = expression_map.merge(hour: tod.hour, minute: tod.minute, second: tod.second)
            end
            expression_map
          end

          #
          # Create a cron trigger based on item type
          #
          # @param [Config] config Rule configuration
          # @param [Object] attach object to be attached to the trigger
          #
          #
          def trigger(config:, attach:)
            CronHandler::CronTriggerHandlerFactory.instance # ensure it's registered
            append_trigger(type: CRON_TRIGGER_MODULE_ID, config: config, attach: attach)
          end
        end
      end
    end
  end
end
