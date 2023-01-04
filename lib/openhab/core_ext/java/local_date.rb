# frozen_string_literal: true

require_relative "time"

module OpenHAB
  module CoreExt
    module Java
      java_import java.time.LocalDate

      # Extensions to {java.time.LocalDate}
      class LocalDate
        include Time
        include Between
        include Ephemeris

        # @!scope class

        # @!attribute [r] now
        #   @return [LocalDate]

        # @!method parse(text, formatter=nil)
        #   Converts the given text into a LocalDate.
        #   @param [String] text The text to parse
        #   @param [java.time.format.DateTimeFormatter] formatter The formatter to use
        #   @return [LocalDate]

        # @!scope instance

        # @param [TemporalAmount, LocalDate, Numeric] other
        #   If other is a Numeric, it's interpreted as days.
        # @return [LocalDate] If other is a TemporalAmount or Numeric
        # @return [Period] If other is a LocalDate
        def -(other)
          case other
          when Date
            self - other.to_local_date
          when MonthDay
            self - other.at_year(year)
          when LocalDate
            Period.between(other, self)
          when Duration
            minus_days(other.to_days)
          when Numeric
            minus_days(other.ceil)
          else
            minus(other)
          end
        end

        # @param [TemporalAmount, Numeric] other
        #   If other is a Numeric, it's interpreted as days.
        # @return [LocalDate]
        def +(other)
          case other
          when Duration
            plus_days(other.to_days)
          when Numeric
            plus_days(other.to_i)
          else
            plus(other)
          end
        end

        #
        # Returns the next day
        #
        # @return [LocalDate]
        #
        def succ
          plus_days(1)
        end

        # @return [Date]
        def to_date
          Date.new(year, month_value, day_of_month)
        end

        # @return [Month]
        alias_method :to_month, :month

        # @return [MonthDay]
        def to_month_day
          MonthDay.of(month, day_of_month)
        end

        # @return [self]
        def to_local_date(_context = nil)
          self
        end

        # @param [ZonedDateTime, nil] context
        #   A {ZonedDateTime} used to fill in missing fields
        #   during conversion. {ZonedDateTime.now} is assumed if not given.
        # @return [ZonedDateTime]
        def to_zoned_date_time(context = nil)
          zone = context&.zone || java.time.ZoneId.system_default
          at_start_of_day(zone)
        end
      end
    end
  end
end

LocalDate = OpenHAB::CoreExt::Java::LocalDate unless Object.const_defined?(:LocalDate)
