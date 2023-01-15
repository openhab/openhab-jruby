# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Java
      Duration = java.time.Duration

      # Extensions to {java.time.Duration Java Duration}
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

        # @return [Integer, nil]
        def <=>(other)
          return to_f <=> other if other.is_a?(Numeric)

          super
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
          return [other.to_i.seconds, self] if other.is_a?(Period)
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
          #   elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
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
              elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
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
          #   elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
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
              elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
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
