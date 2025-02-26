# frozen_string_literal: true

require "forwardable"

# Extensions to Time
class Time
  extend Forwardable
  include OpenHAB::CoreExt::Between
  include OpenHAB::CoreExt::Ephemeris

  #
  # @!method +(other)
  #
  # Extends {#+} to allow adding a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  # @param [java.time.temporal.TemporalAmount] other
  # @return [ZonedDateTime] If other is a {java.time.temporal.TemporalAmount TemporalAmount}
  # @return [Time] If other is a Numeric
  #
  def plus_with_temporal(other)
    return to_zoned_date_time + other.to_temporal_amount if other.respond_to?(:to_temporal_amount)

    plus_without_temporal(other)
  end
  alias_method :plus_without_temporal, :+
  alias_method :+, :plus_with_temporal

  #
  # @!method -(other)
  #
  # Extends {#-} to allow subtracting a {java.time.temporal.TemporalAmount TemporalAmount}
  # or any other date/time class that responds to #to_zoned_date_time.
  #
  # Subtractions with another object of the same class (e.g. Time - Other Time, or DateTime - Other DateTime)
  # remains unchanged from its original behavior.
  #
  # @example Time - Duration -> ZonedDateTime
  #   zdt_one_hour_ago = Time.now - 1.hour
  #
  # @example Time - ZonedDateTime -> Duration
  #   java_duration = Time.now - 1.hour.ago
  #
  # @example Time - Numeric -> Time
  #   time_one_hour_ago = Time - 3600
  #
  # @example Time - Time -> Float
  #   one_day_in_secs = Time.new(2002, 10, 31) - Time.new(2002, 10, 30)
  #
  # @param [java.time.temporal.TemporalAmount, #to_zoned_date_time] other
  # @return [ZonedDateTime] If other is a {java.time.temporal.TemporalAmount TemporalAmount}
  # @return [Duration] If other responds to #to_zoned_date_time
  # @return [Time] If other is a Numeric
  # @return [Float] If other is a Time
  #
  def minus_with_temporal(other)
    return to_zoned_date_time - other.to_temporal_amount if other.respond_to?(:to_temporal_amount)

    # Exclude subtracting against the same class
    if other.respond_to?(:to_zoned_date_time) && !other.is_a?(self.class)
      return to_zoned_date_time - other.to_zoned_date_time
    end

    minus_without_temporal(other)
  end
  alias_method :minus_without_temporal, :-
  alias_method :-, :minus_with_temporal

  # @return [LocalDate]
  def to_local_date(_context = nil)
    java.time.LocalDate.of(year, month, day)
  end

  # @!method to_local_time
  #   @return [LocalTime]
  def_delegator :to_zoned_date_time, :to_local_time

  # @return [Month]
  def to_month
    java.time.Month.of(month)
  end

  # @return [MonthDay]
  def to_month_day
    java.time.MonthDay.of(month, day)
  end

  # @!method yesterday?
  #   (see OpenHAB::CoreExt::Java::ZonedDateTime#yesterday?)
  # @!method today?
  #   (see OpenHAB::CoreExt::Java::ZonedDateTime#today?)
  # @!method tomorrow?
  #   (see OpenHAB::CoreExt::Java::ZonedDateTime#tomorrow?)
  def_delegators :to_zoned_date_time, :yesterday?, :today?, :tomorrow?

  # @param [ZonedDateTime, nil] context
  #   A {ZonedDateTime} used to fill in missing fields
  #   during conversion. Not used in this class.
  # @return [ZonedDateTime]
  def to_zoned_date_time(context = nil) # rubocop:disable Lint/UnusedMethodArgument
    to_java(java.time.ZonedDateTime)
  end

  # @return [Instant]
  def to_instant(_context = nil)
    to_java(java.time.Instant)
  end

  #
  # Converts to a {ZonedDateTime} if `other`
  # is also convertible to a ZonedDateTime.
  #
  # @param [#to_zoned_date_time] other
  # @return [Array, nil]
  #
  def coerce(other)
    logger.trace { "Coercing #{self} as a request from #{other.class}" }
    return unless other.respond_to?(:to_zoned_date_time)

    zdt = to_zoned_date_time
    [other.to_zoned_date_time(zdt), zdt]
  end
end
