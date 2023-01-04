# frozen_string_literal: true

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.DateTimeItem

      #
      # A DateTimeItem stores a timestamp including a valid time zone.
      #
      # @!attribute [r] state
      #   @return [DateTimeType, nil]
      #
      # @example DateTime items can be updated and commanded with Ruby Time objects or Java ZonedDateTime objects
      #   Example_DateTimeItem << Time.now
      #   Example_DateTimeItem << ZonedDateTime.now
      #
      # @example Math operations (+ and -) are available to make calculations with time in a few different ways
      #   Example_DateTimeItem.state + 600 # Number of seconds
      #   Example_DateTimeItem.state - '01:15' # Subtracts 1h 15 min
      #   Example_DateTimeItem.state + 2.hours # Use the helper library's duration methods
      #
      #   Example_DateTimeItem.state - Example_DateTimeItem2.state # Calculate the time difference, in seconds
      #   Example_DateTimeItem.state - '2021-01-01 15:40' # Calculates time difference
      #
      # @example Comparisons between different time objects can be performed
      #   Example_DateTimeItem.state == Example_DateTimeItem2.state # Equality, works across time zones
      #   Example_DateTimeItem.state > Date.parse('2021-01-31') # After midnight jan 31st 2021
      #   Example_DateTimeItem.state <= Time.now # Before or equal to now
      #   Example_DateTimeItem.state < LocalTime::NOON # Before noon
      #
      # @example LocalTime ranges created also work
      #   case Example_DateTimeItem.state
      #   when LocalTime.parse('00:00')...LocalTime.parse('08:00')
      #     logger.info('Example_DateTimeItem is between 00:00..08:00')
      #   when LocalTime.parse('08:00')...LocalTime.parse('16:00')
      #     logger.info('Example_DateTimeItem is between 08:00..16:00')
      #   when LocalTime.parse('16:00')..LocalTime.parse'23:59')
      #     logger.info('Example_DateTimeItem is between 16:00...23:59')
      #   end
      #
      class DateTimeItem < GenericItem
        # Time types need formatted as ISO8601
        # @!visibility private
        def format_type(command)
          return command if command.is_a?(Types::DateTimeType)
          return Types::DateTimeType.new(command.to_zoned_date_time) if command.respond_to?(:to_zoned_date_time)

          super
        end
      end
    end
  end
end

# @!parse DateTimeItem = OpenHAB::Core::Items::DateTimeItem
