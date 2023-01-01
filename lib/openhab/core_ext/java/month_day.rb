# frozen_string_literal: true

require_relative "time"

module OpenHAB
  module CoreExt
    module Java
      java_import java.time.MonthDay

      # Extensions to MonthDay
      class MonthDay
        include Between
        include Ephemeris

        class << self
          #
          # Parses strings in the form "M-d"
          #
          # @param [String] string
          # @return [MonthDay]
          #
          def parse(string)
            logger.trace("#{self.class}.parse #{string} (#{string.class})")
            java_send(:parse, [java.lang.CharSequence, java.time.format.DateTimeFormatter],
                      string.to_s,
                      java.time.format.DateTimeFormatter.ofPattern("[--]M-d"))
          end
        end

        # @return [String]
        def to_s
          # Remove -- from MonthDay string representation
          to_string.delete_prefix("--")
        end
        alias_method :inspect, :to_s

        # wait until we redefine #to_s
        include Time

        # @return [MonthDay]
        def +(other)
          case other
          when java.time.temporal.TemporalAmount, Numeric
            (LocalDate.of(1900, month, day_of_month) + other).to_month_day
          else
            (to_local_date(other.to_local_date) + other).to_month_day
          end
        end

        # @return [MonthDay, Period]
        def -(other)
          d = case other
              when java.time.temporal.TemporalAmount, Numeric
                LocalDate.of(1900, month, day_of_month) - other
              else
                to_local_date(other.to_local_date) - other
              end
          return d if d.is_a?(java.time.Period)

          d.to_month_day
        end

        #
        # Returns the next day
        #
        # Will go to the next month, or loop back to January if necessary.
        #
        # @return [MonthDay]
        #
        def succ
          if day_of_month == month.max_length
            return MonthDay.of(1, 1) if month_value == 12

            return MonthDay.of(month_value + 1, 1)
          end

          MonthDay.of(month_value, day_of_month + 1)
        end

        # @param [TemporalAmount, nil] context
        #   A {TemporalAmount} used to fill in missing
        #   fields during conversion. {LocalDate.now} is assumed if not given.
        # @return [LocalDate]
        def to_local_date(context = nil)
          context ||= java.time.Year.now
          year = java.time.Year.from(context)
          year.at_month_day(self)
        end

        # @return [Month]
        alias_method :to_month, :month

        # @param [Date, nil] context
        #   A {Date} used to fill in missing fields
        #   during conversion. `Date.today` is assumed if not given.
        # @return [Date]
        def to_date(context = nil)
          context ||= Date.today
          Date.new(context.year, month_value, day_of_month)
        end

        # @return [self]
        def to_month_day
          self
        end

        # @param [ZonedDateTime, nil] context
        #   A {ZonedDateTime} used to fill in missing fields
        #   during conversion. {ZonedDateTime.now} is assumed if not given.
        # @return [ZonedDateTime]
        def to_zoned_date_time(context = nil)
          to_local_date(context).to_zoned_date_time(context)
        end
      end
    end
  end
end

MonthDay = OpenHAB::CoreExt::Java::MonthDay unless Object.const_defined?(:MonthDay)
