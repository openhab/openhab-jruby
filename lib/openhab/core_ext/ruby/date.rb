# frozen_string_literal: true

require "forwardable"
require "date"

# Extensions to Date
class Date
  extend Forwardable
  include OpenHAB::CoreExt::Between
  include OpenHAB::CoreExt::Ephemeris

  #
  # Extends {#+} to allow adding a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  # @param [java.time.temporal.TemporalAmount, QuantityType] other
  # @return [LocalDate] If other is a {java.time.temporal.TemporalAmount TemporalAmount} or a Time {QuantityType}
  #
  def plus_with_temporal(other)
    return to_local_date + other.to_temporal_amount if other.respond_to?(:to_temporal_amount)

    plus_without_temporal(other)
  end
  alias_method :plus_without_temporal, :+
  alias_method :+, :plus_with_temporal

  #
  # Extends {#-} to allow subtracting a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  # @param [java.time.temporal.TemporalAmount, QuantityType] other
  # @return [LocalDate] If other is a {java.time.temporal.TemporalAmount TemporalAmount} or a Time {QuantityType}
  #
  def minus_with_temporal(other)
    if other.instance_of?(java.time.LocalDate)
      to_local_date - other
    elsif other.respond_to?(:to_temporal_amount)
      to_local_date - other.to_temporal_amount
    else
      minus_without_temporal(other)
    end
  end
  alias_method :minus_without_temporal, :-
  alias_method :-, :minus_with_temporal

  # @return [LocalDate]
  def to_local_date(_context = nil)
    java.time.LocalDate.of(year, month, day)
  end

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
  #   A {ZonedDateTime} used to fill in missing fields during conversion.
  #   {OpenHAB::CoreExt::Java::ZonedDateTime.now ZonedDateTime.now} is assumed
  #   if not given.
  # @return [ZonedDateTime]
  def to_zoned_date_time(context = nil)
    to_local_date.to_zoned_date_time(context)
  end

  # @param [ZonedDateTime, nil] context
  #   A {ZonedDateTime} used to fill in missing fields during conversion.
  #   {OpenHAB::CoreExt::Java::ZonedDateTime.now ZonedDateTime.now} is assumed
  #   if not given.
  # @return [Instant]
  def to_instant(context = nil)
    context ||= Instant.now.to_zoned_date_time
    to_zoned_date_time(context).to_instant
  end

  # @return [Integer, nil]
  def compare_with_coercion(other)
    return compare_without_coercion(other) if other.is_a?(self.class)

    return self <=> other.to_date(self) if other.is_a?(java.time.MonthDay)

    if other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
      return lhs <=> rhs
    end

    compare_without_coercion(other)
  end
  alias_method :compare_without_coercion, :<=>
  alias_method :<=>, :compare_with_coercion

  #
  # Convert `other` to Date, if possible.
  #
  # @param [#to_date] other
  # @return [Array, nil]
  #
  def coerce(other)
    logger.trace { "Coercing #{self} as a request from #{other.class}" }
    return nil unless other.respond_to?(:to_date)
    return [other.to_date, self] if other.method(:to_date).arity.zero?

    [other.to_date(self), self]
  end

  remove_method :inspect
  # @return [String]
  alias_method :inspect, :to_s
end
