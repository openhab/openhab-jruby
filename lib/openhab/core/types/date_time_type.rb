# frozen_string_literal: true

require "forwardable"
require "time"

require_relative "type"

module OpenHAB
  module Core
    module Types
      DateTimeType = org.openhab.core.library.types.DateTimeType

      # {DateTimeType} uses a {ZonedDateTime} internally.
      class DateTimeType
        # @!parse include Command, State

        # remove the JRuby default == so that we can inherit the Ruby method
        remove_method :==

        extend Forwardable

        # @deprecated OH 4.2 DateTimeType implements Java's Comparable interface in openHAB 4.3
        if OpenHAB::Core.version >= OpenHAB::Core::V4_3
          include ComparableType
        else
          include Comparable
        end

        class << self
          #
          # Parse a time string into a {DateTimeType}.
          #
          # @note openHAB's DateTimeType.new(String) constructor will parse time-only strings and fill in `1970-01-01`
          #   as the date, whereas this method will use the current date.
          #
          # @param (see DSL#try_parse_time_like)
          # @return [DateTimeType]
          #
          def parse(time_string)
            DateTimeType.new(DSL.try_parse_time_like(time_string).to_zoned_date_time)
          rescue ArgumentError
            raise ArgumentError, e.message
          end
        end

        # @deprecated OH 4.2 Just call zoned_date_time(ZoneId.system_default) in OH 4.3
        if OpenHAB::Core.version >= OpenHAB::Core::V4_3
          def to_zoned_date_time(context = nil) # rubocop:disable Lint/UnusedMethodArgument
            zoned_date_time(ZoneId.system_default)
          end
        else
          def to_zoned_date_time(context = nil) # rubocop:disable Lint/UnusedMethodArgument
            zoned_date_time
          end
        end

        # @!method to_zoned_date_time(context = nil)
        # @param [ZonedDateTime, nil] context
        #   A {ZonedDateTime} used to fill in missing fields during conversion. Not used in this class.
        # @return [ZonedDateTime]

        # @!visibility private
        alias_method :to_instant, :get_instant

        # @!method to_instant
        # @return [Instant]

        # @deprecated These methods have been deprecated in openHAB 4.3.
        # act like a Ruby Time
        def_delegator :zoned_date_time, :month_value, :month
        def_delegator :zoned_date_time, :day_of_month, :mday
        def_delegator :zoned_date_time, :day_of_year, :yday
        def_delegator :zoned_date_time, :minute, :min
        def_delegator :zoned_date_time, :second, :sec
        def_delegator :zoned_date_time, :nano, :nsec
        def_delegator :zoned_date_time, :to_time

        # NOTE: to_i is supported by both Instant and ZonedDateTime in #method_missing

        # @!method to_i
        # Returns the value of time as an integer number of seconds since the Epoch
        # @return [Integer] Number of seconds since the Epoch

        # @!visibility private
        alias_method :day, :mday

        #
        # Create a new instance of DateTimeType
        #
        # @param value [#to_zoned_date_time, #to_time, #to_str, #to_d, nil]
        #
        def initialize(value = nil)
          if value.nil?
            super()
            return
          elsif OpenHAB::Core.version >= OpenHAB::Core::V4_3 && value.respond_to?(:to_instant)
            super(value.to_instant)
            return
          elsif value.respond_to?(:to_zoned_date_time)
            super(value.to_zoned_date_time)
            return
          elsif value.respond_to?(:to_time)
            super(value.to_time.to_zoned_date_time)
            return
          elsif value.respond_to?(:to_str)
            # strings respond_do?(:to_d), but we want to avoid that conversion
            super(value.to_str)
            return
          elsif value.respond_to?(:to_d)
            super(Time.at(value.to_d).to_zoned_date_time)
            return
          end

          super
        end

        #
        # Check equality without type conversion
        #
        # @return [true,false] if the same value is represented, without type
        #   conversion
        def eql?(other)
          return false unless other.instance_of?(self.class)

          # @deprecated OH 4.2 Call compare_to(other).zero? in OH 4.3 to avoid the deprecated getZonedDateTime()
          return compare_to(other).zero? if OpenHAB::Core.version >= OpenHAB::Core::V4_3

          zoned_date_time.compare_to(other.zoned_date_time).zero?
        end

        #
        # Comparison
        #
        # @param [Object] other object to compare to
        #
        # @return [Integer, nil] -1, 0, +1 depending on whether `other` is
        #   less than, equal to, or greater than self
        #
        #   `nil` is returned if the two values are incomparable.
        #
        def <=>(other)
          logger.trace { "(#{self.class}) #{self} <=> #{other} (#{other.class})" }
          if other.is_a?(self.class)
            # @deprecated OH 4.2 Call compare_to(other) in OH 4.3 to avoid the deprecated getZonedDateTime()
            return compare_to(other) if OpenHAB::Core.version >= OpenHAB::Core::V4_3

            zoned_date_time <=> other.zoned_date_time
          elsif other.respond_to?(:to_time)
            to_time <=> other.to_time
          elsif other.respond_to?(:coerce)
            return nil unless (lhs, rhs = other.coerce(self))

            lhs <=> rhs
          end
        end

        #
        # Type Coercion
        #
        # Coerce object to a DateTimeType
        #
        # @param [Time] other object to coerce to a DateTimeType
        #
        # @return [[DateTimeType, DateTimeType], nil]
        #
        def coerce(other)
          logger.trace { "Coercing #{self} as a request from #{other.class}" }
          return [other, to_instant] if other.respond_to?(:to_instant)
          return [other, zoned_date_time] if other.respond_to?(:to_zoned_date_time)

          [DateTimeType.new(other), self] if other.respond_to?(:to_time)
        end

        #
        # Returns the value of time as a floating point number of seconds since the Epoch
        #
        # @return [Float] Number of seconds since the Epoch, with nanosecond presicion
        #
        def to_f
          to_instant.then { |instant| instant.epoch_second + (instant.nano / 1_000_000_000) }
        end

        #
        # The offset in seconds from UTC
        #
        # @return [Integer] The offset from UTC, in seconds
        #
        # @deprecated This method has been deprecated in openHAB 4.3.
        def utc_offset
          zoned_date_time.offset.total_seconds
        end

        #
        # Returns true if time represents a time in UTC (GMT)
        #
        # @return [true,false] true if utc_offset == 0, false otherwise
        #
        # @deprecated This method has been deprecated in openHAB 4.3.
        def utc?
          utc_offset.zero?
        end

        #
        # Returns an integer representing the day of the week, 0..6, with Sunday == 0.
        #
        # @return [Integer] The day of week
        #
        # @deprecated This method has been deprecated in openHAB 4.3.
        def wday
          zoned_date_time.day_of_week.value % 7
        end

        #
        # The timezone
        #
        # @return [String] The timezone in `[+-]hh:mm(:ss)` format (`Z` for UTC)
        #
        # @deprecated This method has been deprecated in openHAB 4.3.
        def zone
          zoned_date_time.zone.id
        end

        # @!visibility private
        def respond_to_missing?(method, _include_private = false)
          # @deprecated OH 4.2 Remove version check when dropping OH 4.2
          return true if OpenHAB::Core.version >= OpenHAB::Core::V4_3 && to_instant.respond_to?(method)
          return true if zoned_date_time.respond_to?(method)
          return true if ::Time.instance_methods.include?(method.to_sym)

          super
        end

        #
        # Forward missing methods to the `ZonedDateTime` object or a ruby `Time`
        # object representing the same instant
        #
        def method_missing(method, ...)
          # @deprecated OH 4.2 Remove version check when dropping OH 4.2
          if OpenHAB::Core.version >= OpenHAB::Core::V4_3 && to_instant.respond_to?(method)
            return to_instant.send(method, ...)
          end

          return zoned_date_time.send(method, ...) if zoned_date_time.respond_to?(method)
          return to_time.send(method, ...) if ::Time.instance_methods.include?(method.to_sym)

          super
        end

        # Add other to self
        #
        # @param other [Duration, Numeric]
        #
        # @return [DateTimeType]
        def +(other)
          if other.is_a?(Duration)
            DateTimeType.new(zoned_date_time.plus(other))
          elsif other.respond_to?(:to_d)
            DateTimeType.new(zoned_date_time.plus_nanos((other.to_d * 1_000_000_000).to_i))
          elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(to_d))
            lhs + rhs
          else
            raise TypeError, "\#{other.class} can't be coerced into \#{self.class}"
          end
        end

        # Subtract other from self
        #
        # if other is a Duration-like object, the result is a new
        # {DateTimeType} of duration seconds earlier in time.
        #
        # if other is a DateTime-like object, the result is a Duration
        # representing how long between the two instants in time.
        #
        # @param other [Duration, Time, Numeric]
        #
        # @return [DateTimeType, Duration]
        def -(other)
          if other.is_a?(Duration)
            DateTimeType.new(zoned_date_time.minus(other))
          elsif other.respond_to?(:to_time)
            to_time - other.to_time
          elsif other.respond_to?(:to_d)
            DateTimeType.new(zoned_date_time.minus_nanos((other.to_d * 1_000_000_000).to_i))
          elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(to_d))
            lhs - rhs
          else
            raise TypeError, "\#{other.class} can't be coerced into \#{self.class}"
          end
        end
      end
    end
  end
end

# @!parse DateTimeType = OpenHAB::Core::Types::DateTimeType
