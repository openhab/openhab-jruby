# frozen_string_literal: true

require "forwardable"

require_relative "time"

module OpenHAB
  module CoreExt
    module Java
      Instant = java.time.Instant

      # Extensions to {java.time.Instant}
      class Instant < java.lang.Object
        extend Forwardable
        include Time
        include Between

        class << self # rubocop:disable Lint/EmptyClass
          # @!scope class

          # @!attribute [r] now
          #   @return [Instant]

          # @!method parse(text, formatter = nil)
          #   Parses a string into an Instant object.
          #
          #   @param [String] text The text to parse.
          #   @param [java.time.format.DateTimeFormatter] formatter The formatter to use.
          #   @return [Instant]
        end

        # @!scope instance

        # @!method to_local_time
        #   @return [LocalTime]
        # @!method to_local_date
        #   @return [LocalDate]
        # @!method to_month_day
        #   @return [MonthDay]
        # @!method to_date
        #   @return [Date]
        # @!method to_month
        #   @return [Month]
        # @!method yesterday?
        #   (see OpenHAB::CoreExt::Java::ZonedDateTime#yesterday?)
        # @!method today?
        #   (see OpenHAB::CoreExt::Java::ZonedDateTime#today?)
        # @!method tomorrow?
        #   (see OpenHAB::CoreExt::Java::ZonedDateTime#tomorrow?)
        def_delegators :to_zoned_date_time,
                       :to_local_time,
                       :to_local_date,
                       :to_date,
                       :to_month_day,
                       :to_month,
                       :yesterday?,
                       :today?,
                       :tomorrow?

        # @param [TemporalAmount, #to_instant, #to_zoned_date_time, Numeric] other
        #   If other is a Numeric, it's interpreted as seconds.
        # @return [Duration] If other responds to #to_zoned_date_time
        # @return [Instant] If other is a TemporalAmount
        def -(other)
          if other.is_a?(Instant)
            java.time.Duration.between(other, self)
          elsif other.respond_to?(:to_instant)
            java.time.Duration.between(other.to_instant, self)
          elsif other.respond_to?(:to_zoned_date_time)
            java.time.Duration.between(other.to_zoned_date_time.to_instant, self)
          elsif other.is_a?(Numeric)
            minus(other.seconds)
          else
            minus(other)
          end
        end

        # @param [TemporalAmount, Numeric] other
        #   If other is a Numeric, it's interpreted as seconds.
        # @return [Instant]
        def +(other)
          return plus(other.seconds) if other.is_a?(Numeric)

          plus(other)
        end

        #
        # The number of seconds since the Unix epoch.
        # @return [Integer]
        #
        def to_i
          epoch_second
        end

        #
        # The number of seconds since the Unix epoch.
        # @return [Float]
        #
        def to_f
          ((epoch_second * 1_000_000_000) + nano).fdiv(1_000_000_000.0)
        end

        # This comes from JRuby

        # @!method to_time
        #   @return [Time]

        # @return [Integer, nil]
        def <=>(other)
          logger.trace { "(#{self.class}) #{self} <=> #{other} (#{other.class})" }
          # compare instants, otherwise it will differ by timezone, which we don't want
          # (use eql? if you care about that)
          if other.respond_to?(:to_instant)
            logger.trace { "Comparing #{self} to #{other.to_instant}" }
            compare_to(other.to_instant(to_zoned_date_time))
          elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
            lhs <=> rhs
          end
        end

        # @param [ZonedDateTime, nil] context A {ZonedDateTime} used to match the zone id. Defaults to UTC.
        # @return [ZonedDateTime]
        def to_zoned_date_time(context = nil)
          zone = context&.zone || java.time.ZoneOffset::UTC
          at_zone(zone)
        end

        # @!visibility private
        def to_instant(_context = nil)
          self
        end

        #
        # Converts `other` to {Instant}, if possible
        #
        # @param [#to_instant] other
        # @return [Array, nil]
        #
        def coerce(other)
          logger.trace { "Coercing #{self} as a request from #{other.class}" }
          return [other.to_instant(to_zoned_date_time), self] if other.respond_to?(:to_instant)

          [other.to_zoned_date_time(zoned_date_time).to_instant, self] if other.respond_to?(:to_zoned_date_time)
        end
      end
    end
  end
end

Instant = OpenHAB::CoreExt::Java::Instant unless Object.const_defined?(:Instant)
