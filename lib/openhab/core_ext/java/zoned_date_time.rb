# frozen_string_literal: true

require_relative "time"

module OpenHAB
  module CoreExt
    module Java
      ZonedDateTime = java.time.ZonedDateTime

      # Extensions to ZonedDateTime
      class ZonedDateTime
        include Time
        include Between

        class << self # rubocop:disable Lint/EmptyClass
          # @!scope class

          # @!attribute [r] now
          #   @return [ZonedDateTime]

          # @!method parse(text, formatter = nil)
          #   Parses a string into a ZonedDateTime object.
          #
          #   @param [String] text The text to parse.
          #   @param [java.time.format.DateTimeFormatter] formatter The formatter to use.
          #   @return [ZonedDateTime]
        end

        # @!scope instance

        # @return [LocalTime]
        def to_local_time(_context = nil)
          toLocalTime
        end

        # @return [Month]
        alias_method :to_month, :month

        # @param [TemporalAmount, #to_zoned_date_time, Numeric] other
        #   If other is a Numeric, it's interpreted as seconds.
        # @return [Duration] If other responds to #to_zoned_date_time
        # @return [ZonedDateTime] If other is a TemporalAmount
        def -(other)
          if other.respond_to?(:to_zoned_date_time)
            java.time.Duration.between(other.to_zoned_date_time, self)
          elsif other.is_a?(Numeric)
            minus(other.seconds)
          else
            minus(other)
          end
        end

        # @param [TemporalAmount, Numeric] other
        #   If other is a Numeric, it's interpreted as seconds.
        # @return [ZonedDateTime]
        def +(other)
          return plus(other.seconds) if other.is_a?(Numeric)

          plus(other)
        end

        #
        # The number of seconds since the Unix epoch.
        #
        # @return [Integer]
        def to_i
          to_instant.epoch_second
        end

        #
        # The number of seconds since the Unix epoch.
        #
        # @return [Float]
        def to_f
          to_instant.to_epoch_milli / 1000.0
        end

        # @return [Date]
        def to_date
          Date.new(year, month_value, day_of_month)
        end

        # @return [LocalDate]
        def to_local_date(_context = nil)
          toLocalDate
        end

        # @return [MonthDay]
        def to_month_day
          MonthDay.of(month, day_of_month)
        end

        # This comes from JRuby

        # @!method to_time
        #   @return [Time]

        # @param [ZonedDateTime, nil] context
        #   A {ZonedDateTime} used to fill in missing fields
        #   during conversion. Not used in this class.
        # @return [self]
        def to_zoned_date_time(context = nil) # rubocop:disable Lint/UnusedMethodArgument
          self
        end

        # @group Ephemeris Methods
        #   (see CoreExt::Ephemeris)

        #
        # Name of the holiday for this date.
        #
        # @param [String, nil] holiday_file Optional path to XML file to use for holiday definitions.
        # @return [Symbol, nil]
        #
        # @example
        #   MonthDay.parse("12-25").holiday # => :christmas
        #
        def holiday(holiday_file = nil)
          ::Ephemeris.get_bank_holiday_name(*[self, holiday_file || DSL.holiday_file].compact)&.downcase&.to_sym
        end

        #
        # Determines if this date is on a holiday.
        #
        # @param [String, nil] holiday_file Optional path to XML file to use for holiday definitions.
        # @return [true, false]
        #
        def holiday?(holiday_file = nil)
          ::Ephemeris.bank_holiday?(*[self, holiday_file || DSL.holiday_file].compact)
        end

        #
        # Name of the closest holiday on or after this date.
        #
        # @param [String, nil] holiday_file Optional path to XML file to use for holiday definitions.
        # @return [Symbol]
        #
        def next_holiday(holiday_file = nil)
          ::Ephemeris.get_next_bank_holiday(*[self, holiday_file || DSL.holiday_file].compact).downcase.to_sym
        end

        #
        # Determines if this time is during a weekend.
        #
        # @return [true, false]
        #
        # @example
        #   Time.now.weekend?
        #
        def weekend?
          ::Ephemeris.weekend?(self)
        end

        #
        # Determines if this time is during a specific dayset
        #
        # @param [String, Symbol] set
        # @return [true, false]
        #
        # @example
        #   Time.now.in_dayset?("school")
        #
        def in_dayset?(set)
          ::Ephemeris.in_dayset?(set.to_s, self)
        end

        #
        # Calculate the number of days until a specific holiday
        #
        # @param [String, Symbol] holiday
        # @param [String, nil] holiday_file Optional path to XML file to use for holiday definitions.
        # @return [Integer]
        # @raise [ArgumentError] if the holiday isn't valid
        #
        # @example
        #   Time.now.days_until(:christmas) # => 2
        #
        def days_until(holiday, holiday_file = nil)
          holiday = holiday.to_s.upcase
          r = ::Ephemeris.get_days_until(*[self, holiday, holiday_file || DSL.holiday_file].compact)
          raise ArgumentError, "#{holiday.inspect} isn't a recognized holiday" if r == -1

          r
        end

        # @endgroup

        # @return [Integer, nil]
        def <=>(other)
          # compare instants, otherwise it will differ by timezone, which we don't want
          # (use eql? if you care about that)
          if other.respond_to?(:to_zoned_date_time)
            to_instant.compare_to(other.to_zoned_date_time(self).to_instant)
          elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
            lhs <=> rhs
          end
        end

        #
        # Converts `other` to {ZonedDateTime}, if possible
        #
        # @param [#to_zoned_date_time] other
        # @return [Array, nil]
        #
        def coerce(other)
          [other.to_zoned_date_time(self), self] if other.respond_to?(:to_zoned_date_time)
        end
      end
    end
  end
end

# @!parse ZonedDateTime = OpenHAB::CoreExt::Java::ZonedDateTime
