# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Java
      Duration = java.time.Duration

      #
      # Extensions to {java.time.Duration Java Duration}
      #
      # Ruby's {Integer} and {Float} classes are extended to allow convenient creation of {Duration} instances.
      #
      # @example
      #   5.seconds # => #<Duration PT5S>
      #   2.5.hours # => #<Duration PT2H30M>
      #
      class Duration
        include Between

        # @!parse include TemporalAmount

        #
        # Convert to integer number of seconds
        #
        # @return [Integer]
        #
        alias_method :to_i, :seconds

        #
        # @!method zero?
        #   @return [true,false] Returns true if the duration is zero length.
        #

        #
        # @!method negative?
        #   @return [true,false] Returns true if the duration is less than zero.
        #

        unless instance_methods.include?(:positive?)
          #
          # @return [true, false] Returns true if the duration is greater than zero.
          #
          def positive?
            self > 0 # rubocop:disable Style/NumericPredicate
          end
        end

        #
        # Convert to number of seconds
        #
        # @return [Float]
        #
        def to_f
          to_i + (nano / 1_000_000_000.0)
        end

        remove_method :==

        #
        # Comparisons against other types may be done if supported by that type's coercion.
        #
        # @return [Numeric, QuantityType, nil]
        #
        def <=>(other)
          logger.trace { "(#{self.class}) #{self} <=> #{other} (#{other.class})" }
          case other
          when Duration then super
          when Numeric then to_f <=> other
          when QuantityType then self <=> other.to_temporal_amount
          else
            if other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
              lhs <=> rhs
            else
              super
            end
          end
        rescue TypeError
          nil
        end

        #
        # Converts `other` to {Duration}, if possible.
        #
        # @param [Numeric, Period] other
        # @return [Array, nil]
        #
        def coerce(other)
          return [other.seconds, self] if other.is_a?(Numeric)
          # We want to return the same type as other, e.g. QuantityType + Duration = QuantityType
          return [other, to_nanos | "ns"] if other.is_a?(QuantityType) && other.unit.compatible?(Units::SECOND)

          [other.to_i.seconds, self] if other.is_a?(Period)
        end

        {
          plus: :+,
          minus: :-
        }.each do |java_op, ruby_op|
          # def +(other)
          #   if other.is_a?(Duration)
          #     plus(other)
          #   elsif other.is_a?(Integer)
          #     plus_seconds(other)
          #   elsif other.is_a?(Numeric)
          #     plus(other.seconds)
          #   elsif other.is_a?(QuantityType)
          #     plus(other.to_temporal_amount)
          #   elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
          #     lhs + rhs
          #   else
          #     raise TypeError, "#{other.class} can't be coerced into Duration"
          #   end
          # end
          class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
            def #{ruby_op}(other)
              if other.is_a?(Duration)
                #{java_op}(other)
              elsif other.is_a?(Integer)
                #{java_op}_seconds(other)
              elsif other.is_a?(Numeric)
                #{java_op}(other.seconds)
              elsif other.is_a?(QuantityType)
                #{java_op}(other.to_temporal_amount)
              elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
                lhs #{ruby_op} rhs
              else
                raise TypeError, "\#{other.class} can't be coerced into Duration"
              end
            end
          RUBY
        end

        {
          multipliedBy: :*,
          dividedBy: :/
        }.each do |java_op, ruby_op|
          # def *(other)
          #   if other.is_a?(Integer)
          #     multipliedBy(other)
          #   elsif other.is_a?(Numeric)
          #     Duration.of_seconds(to_f * other)
          #   elsif other.is_a?(Duration)
          #     Duration.of_seconds(to_f * other.to_f)
          #   elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
          #     lhs * rhs
          #   else
          #     raise TypeError, "#{other.class} can't be coerced into Duration"
          #   end
          # end
          class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
            def #{ruby_op}(other)
              if other.is_a?(Integer)
                #{java_op}(other)
              elsif other.is_a?(Numeric)
                Duration.of_seconds(to_f #{ruby_op} other)
              elsif other.is_a?(Duration)
                Duration.of_seconds(to_f #{ruby_op} other.to_f)
              elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(self))
                lhs #{ruby_op} rhs
              else
                raise TypeError, "\#{other.class} can't be coerced into Duration"
              end
            end
          RUBY
        end
      end
    end
  end
end

# @!parse Duration = OpenHAB::CoreExt::Java::Duration
