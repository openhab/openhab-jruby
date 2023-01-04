# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Java
      java_import java.time.temporal.TemporalAmount

      # Extensions to {java.time.temporal.TemporalAmount}
      module TemporalAmount
        # Subtract `self` to {ZonedDateTime.now}
        # @return [ZonedDateTime]
        def ago
          ZonedDateTime.now - self
        end

        # Add `self` to {ZonedDateTime.now}
        # @return [ZonedDateTime]
        def from_now
          ZonedDateTime.now + self
        end

        # @return [TemporalAmount]
        def -@
          negated
        end

        # @return [String]
        def inspect
          to_s
        end
      end
    end
  end
end
