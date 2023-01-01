# frozen_string_literal: true

require "date"

# Extensions to Date
class Date
  include OpenHAB::CoreExt::Between
  include OpenHAB::CoreExt::Ephemeris

  #
  # Extends {#+} to allow adding a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  # @param [java.time.temporal.TemporalAmount] other
  # @return [LocalDate] If other is a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  def plus_with_temporal(other)
    return to_local_date + other if other.is_a?(java.time.temporal.TemporalAmount)

    plus_without_temporal(other)
  end
  alias_method :plus_without_temporal, :+
  alias_method :+, :plus_with_temporal

  #
  # Extends {#-} to allow subtracting a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  # @param [java.time.temporal.TemporalAmount] other
  # @return [LocalDate] If other is a {java.time.temporal.TemporalAmount TemporalAmount}
  #
  def minus_with_temporal(other)
    case other
    when java.time.temporal.TemporalAmount, java.time.LocalDate
      to_local_date - other
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

  # @param [ZonedDateTime, nil] context
  #   A {ZonedDateTime} used to fill in missing fields during conversion.
  #   {OpenHAB::CoreExt::Java::ZonedDateTime.now ZonedDateTime.now} is assumed
  #   if not given.
  # @return [ZonedDateTime]
  def to_zoned_date_time(context = nil)
    to_local_date.to_zoned_date_time(context)
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
    return nil unless other.respond_to?(:to_date)
    return [other.to_date, self] if other.method(:to_date).arity.zero?

    [other.to_date(self), self]
  end

  remove_method :inspect
  # @return [String]
  alias_method :inspect, :to_s
end
