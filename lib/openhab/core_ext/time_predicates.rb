# frozen_string_literal: true

module OpenHAB
  module CoreExt
    # Predicate helpers for date/time-like objects.
    module TimePredicates
      #
      # Checks whether the object is within a maximum allowable distance (epsilon)
      # of a specific anchor time.
      #
      # @example Check if a timestamp is within 5 minutes of right now
      #   event_time.within?(5.minutes)
      #
      # @example Check if a timestamp is within 30 seconds of an explicit execution deadline
      #   log_time.within?(30.seconds, of: deadline)
      #
      # @param [java.time.temporal.TemporalAmount, Numeric] epsilon the maximum allowable time difference/distance
      # @param [ZonedDateTime, Time] of the anchor time to compare against (defaults to now)
      # @return [true, false] true if the absolute difference between self and the anchor is less than epsilon
      #
      def within?(epsilon, of: ZonedDateTime.now)
        # Convert times to a common float representation (like epoch seconds) to do the math
        # Or use native Java duration differences if keeping it in the Java ecosystem
        (of - self).to_f.abs < epsilon.to_f
      end
    end
  end
end
