# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Java
      java_import java.time.Period

      # Extensions to {java.time.Period}
      class Period
        # @!parse include TemporalAmount

        #
        # Convert to number of seconds
        #
        # @return [Integer]
        #
        def to_i
          [java.time.temporal.ChronoUnit::YEARS,
           java.time.temporal.ChronoUnit::MONTHS,
           java.time.temporal.ChronoUnit::DAYS].sum do |unit|
            get(unit) * unit.duration.to_i
          end
        end

        #
        # Convert to number of seconds
        #
        # @return [Float]
        #
        def to_f
          to_i.to_f
        end

        remove_method :==

        # @return [Integer, nil]
        def <=>(other)
          return to_i <=> other if other.is_a?(Numeric)

          super
        end

        #
        # Convert `self` and `other` to {Duration}, if `other` is a Numeric
        #
        # @param [Numeric] other
        # @return [Array, nil]
        #
        def coerce(other)
          return [other.seconds, to_i.seconds] if other.is_a?(Numeric)
        end

        {
          plus: :+,
          minus: :-
        }.each do |java_op, ruby_op|
          # def +(other)
          #   if other.is_a?(Period)
          #     plus(other)
          #   elsif other.is_a?(Numeric)
          #     self + other.seconds
          #   elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
          #     lhs + rhs
          #   else
          #     raise TypeError, "#{other.class} can't be coerced into Period"
          #   end
          # end
          class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
            def #{ruby_op}(other)
              if other.is_a?(Period)
                #{java_op}(other)
              elsif other.is_a?(Numeric)
                self #{ruby_op} other.seconds
              elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
                lhs #{ruby_op} rhs
              else
                raise TypeError, "\#{other.class} can't be coerced into Period"
              end
            end
          RUBY
        end

        # @!visibility private
        def *(other)
          if other.is_a?(Integer)
            multipliedBy(other)
          elsif other.respond_to?(:coerce) && (rhs, lhs = other.coerce(self))
            lhs * rhs
          else
            raise TypeError, "#{other.class} can't be coerced into Period"
          end
        end

        # @!visibility private
        def /(other)
          to_f.seconds / other
        end
      end
    end
  end
end

Period = OpenHAB::CoreExt::Java::Period unless Object.const_defined?(:Period)
