# frozen_string_literal: true

require "date"
require "forwardable"

# DateTime inherits from Date, but is more similar to Time semantically.
# So it avoid alias_method chain bombs, and to ensure the correct end methods
# exist here, we define the important methods from Time here as well.

# Extensions to DateTime
class DateTime < Date
  extend Forwardable
  include OpenHAB::CoreExt::Between
  include OpenHAB::CoreExt::Ephemeris

  # (see Time#plus_with_temporal)
  def plus_with_temporal(other)
    return to_zoned_date_time + other.to_temporal_amount if other.respond_to?(:to_temporal_amount)

    plus_without_temporal(other)
  end
  # alias_method :plus_without_temporal, :+ # already done by Date
  alias_method :+, :plus_with_temporal

  # (see Time#minus_with_temporal)
  def minus_with_temporal(other)
    return to_zoned_date_time - other.to_temporal_amount if other.respond_to?(:to_temporal_amount)

    # Exclude subtracting against the same class
    if other.respond_to?(:to_zoned_date_time) && !other.is_a?(self.class)
      return to_zoned_date_time - other.to_zoned_date_time
    end

    minus_without_temporal(other)
  end
  # alias_method :minus_without_temporal, :- # already done by Date
  alias_method :-, :minus_with_temporal

  # @!method to_local_time
  #   @return [LocalTime]
  def_delegator :to_zoned_date_time, :to_local_time

  # (see Time#to_zoned_date_time)
  def to_zoned_date_time(context = nil) # rubocop:disable Lint/UnusedMethodArgument
    to_java(ZonedDateTime)
  end

  # @return [Instant]
  def to_instant(_context = nil)
    to_java(Instant)
  end

  # (see Time#coerce)
  def coerce(other)
    logger.trace { "Coercing #{self} as a request from #{other.class}" }
    return unless other.respond_to?(:to_zoned_date_time)

    zdt = to_zoned_date_time
    [other.to_zoned_date_time(zdt), zdt]
  end
end
