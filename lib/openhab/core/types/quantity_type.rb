# frozen_string_literal: true

require_relative "numeric_type"
require_relative "type"

module OpenHAB
  module Core
    module Types
      QuantityType = org.openhab.core.library.types.QuantityType

      #
      # {QuantityType} extends {DecimalType} to handle physical unit measurement.
      #
      # {QuantityType} is part of the [Units of Measurement](https://www.openhab.org/docs/concepts/units-of-measurement.html)
      # framework in openHAB. It is represented as a decimal number with a unit.
      # You can construct a {QuantityType} object by using the pipe operator with any Numeric.
      #
      # @see OpenHAB::DSL.unit unit: Implicit unit conversions
      # @see OpenHAB::CoreExt::Ruby::QuantityTypeConversion Convert Numeric to QuantityType
      #
      # @example QuantityTypes can perform math operations between them.
      #   (50 | "°F") + (-25 | "°F") # => 25.0 °F
      #   (100 | "°F") / (2 | "°F") # => 50
      #   (50 | "°F") - (25 | "°F") # => 25 °F
      #   (50 | "°F") + (50 | "°F") # => 100 °F
      #
      # @example If the operand is a number, it will be unit-less, but the result of the operation will have a unit. This only works for multiplication and division.
      #   (50 | "°F") * 2 # => 100 °F
      #   (100 | "°F") / 2 # => 50 °F
      #
      # @example If the operand is a dimensioned NumberItem it will automatically be converted to a quantity for the operation.
      #   # NumberF = "2 °F"
      #   # NumberC = "2 °C"
      #   (50 | "°F") + NumberF.state # => 52.0 °F
      #   (50 | "°F") + NumberC.state # => 85.60 °F
      #
      # @example If the operand is a non-dimensioned NumberItem it can be used only in multiplication and division operations.
      #   # Number Dimensionless = 2
      #   (50 | "°F") * Dimensionless.state # => 100 °F
      #   (50 | "°F") / Dimensionless.state # => 25 °F
      #
      # @example Quantities can be compared, if they have comparable units.
      #   (50 | "°F") >  (25 | "°F")
      #   (50 | "°F") >  (525 | "°F")
      #   (50 | "°F") >= (50 | "°F")
      #   (50 | "°F") == (50 | "°F")
      #   (50 | "°F") <  (25 | "°C")
      #
      # @example A Range can be used with QuantityType:
      #   ((0 | "°C")..(100 | "°C")).cover?(NumberC)
      #
      # @example A Range can also be used in a case statement for a dimensioned item:
      #   description = case NumberC.state
      #                 when (-20 | "°C")...(18 | "°C") then "too cold"
      #                 when (18 | "°C")...(25 | "°C") then "comfortable"
      #                 when (25 | "°C")...(40 | "°C") then "too warm"
      #                 else "out of range"
      #                 end
      #
      # @example Dimensioned Number Items can be converted to quantities with other units using the | operator
      #   # NumberC = "23 °C"
      #
      #   # Using a unit
      #   logger.info("In Fahrenheit #{NumberC.state | ImperialUnits::FAHRENHEIT }")
      #
      #   # Using a string
      #   logger.info("In Fahrenheit #{NumberC.state | "°F"}")
      #
      # @example Dimensionless Number Items can be converted to quantities with units using the | operator
      #   # Dimensionless = 70
      #
      #   # Using a unit
      #   logger.info("In Fahrenheit #{Dimensionless.state | ImperialUnits::FAHRENHEIT }")
      #
      #   # Using a string
      #   logger.info("In Fahrenheit #{Dimensionless.state | "°F"}")
      #
      # @example Dimensioned Number Items automatically use their units and convert automatically for math operations
      #   # Number:Temperature NumberC = 23 °C
      #   # Number:Temperature NumberF = 70 °F
      #   NumberC.state - NumberF.state # => 1.88 °C
      #   NumberF.state + NumberC.state # => 143.40 °F
      #
      # @example Dimensionless Number Items can be used for multiplication and division.
      #   # Number Dimensionless = 2
      #   # Number:Temperature NumberF = 70 °F
      #   NumberF.state * Dimensionless.state # => 140.0 °F
      #   NumberF.state / Dimensionless.state # => 35.0 °F
      #   Dimensionless.state * NumberF.state # => 140.0 °F
      #   2 * NumberF.state                   # => 140.0 °F
      #
      # @example Comparisons work on dimensioned number items with different, but comparable units.
      #   # Number:Temperature NumberC = 23 °C
      #   # Number:Temperature NumberF = 70 °F
      #   NumberC.state > NumberF.state # => true
      #
      # @example For certain unit types, such as temperature, all unit needs to be normalized to the comparator for all operations when combining comparison operators with dimensioned numbers.
      #   (NumberC.state | "°F") - (NumberF.state | "°F") < 4 | "°F"
      #
      class QuantityType
        # @!parse include Command, State
        include NumericType
        include ComparableType

        # @!parse
        #   #
        #   # Convert this {QuantityType} into another unit.
        #   #
        #   # @param [String, javax.measure.units.Unit] unit
        #   # @return [QuantityType]
        #   #
        #   # @example
        #   #   NumberC.state | ImperialUnits::FAHRENHEIT
        #   #
        #   def to_unit(unit); end

        alias_method :|, :to_unit

        #
        # Comparison
        #
        # Comparisons against Numeric and DecimalType are allowed only within a
        # {OpenHAB::DSL.unit unit} block to avoid unit ambiguities.
        # Comparisons against other types may be done if supported by that type's coercion.
        #
        # @param [QuantityType, DecimalType, Numeric, Object]
        #   other object to compare to
        #
        # @return [Integer, nil] -1, 0, +1 depending on whether `other` is
        #   less than, equal to, or greater than self
        #
        #   `nil` is returned if the two values are incomparable.
        #
        def <=>(other)
          logger.trace("(#{self.class}) #{self} <=> #{other} (#{other.class})")
          case other
          when self.class
            return unitize(other.unit).compare_to(other) if unit == Units::ONE
            return compare_to(other.unitize(unit)) if other.unit == Units::ONE

            return compare_to(other)
          when Numeric, DecimalType
            if (unit = OpenHAB::DSL.unit(dimension))
              return compare_to(QuantityType.new(other, unit))
            end

            return nil # don't allow comparison with numeric outside a unit block
          end

          return nil unless other.respond_to?(:coerce)

          other.coerce(self)&.then { |lhs, rhs| lhs <=> rhs }
        end

        #
        # Type Coercion
        #
        # Coerce object to a {QuantityType}
        #
        # @param [Numeric] other object to coerce to a {QuantityType}
        #
        # @return [Array<(QuantityType, QuantityType)>, nil]
        def coerce(other)
          logger.trace("Coercing #{self} as a request from #{other.class}")
          return unless other.respond_to?(:to_d)

          [QuantityType.new(other.to_d.to_java, Units::ONE), self]
        end

        # arithmetic operators
        alias_method :-@, :negate

        {
          add: :+,
          subtract: :-
        }.each do |java_op, ruby_op|
          convert = "self.class.new(other, DSL.unit(dimension) || unit)"

          class_eval( # rubocop:disable Style/DocumentDynamicEvalDefinition https://github.com/rubocop/rubocop/issues/10179
            # def +(other)
            #   logger.trace("#{self} + #{other} (#{other.class})")
            #   if other.is_a?(QuantityType)
            #     add_quantity(other)
            #   elsif other.is_a?(DecimalType)
            #     other = other.to_big_decimal
            #     add_quantity(self.class.new(other, DSL.unit(dimension) || unit))
            #   elsif other.is_a?(java.math.BigDecimal)
            #     add_quantity(self.class.new(other, DSL.unit(dimension) || unit))
            #   elsif other.respond_to?(:to_d)
            #     other = other.to_d.to_java
            #     add_quantity(self.class.new(other, DSL.unit(dimension) || unit))
            #   elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(to_d))
            #     lhs + rhs
            #   else
            #     raise TypeError, "#{other.class} can't be coerced into #{self.class}"
            #   end
            # end
            <<~RUBY, __FILE__, __LINE__ + 1
              def #{ruby_op}(other)
                logger.trace("\#{self} #{ruby_op} \#{other} (\#{other.class})")
                if other.is_a?(QuantityType)
                  #{java_op}_quantity(other)
                elsif other.is_a?(DecimalType)
                  other = other.to_big_decimal
                  #{java_op}_quantity(#{convert})
                elsif other.is_a?(java.math.BigDecimal)
                  #{java_op}_quantity(#{convert})
                elsif other.respond_to?(:to_d)
                  other = other.to_d.to_java
                  #{java_op}_quantity(#{convert})
                elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(to_d))
                  lhs #{ruby_op} rhs
                else
                  raise TypeError, "\#{other.class} can't be coerced into \#{self.class}"
                end
              end
            RUBY
          )
        end

        {
          multiply: :*,
          divide: :/
        }.each do |java_op, ruby_op|
          class_eval( # rubocop:disable Style/DocumentDynamicEvalDefinition https://github.com/rubocop/rubocop/issues/10179
            # def *(other)
            #   logger.trace("#{self} * #{other} (#{other.class})")
            #   if other.is_a?(QuantityType)
            #     multiply_quantity(other)
            #   elsif other.is_a?(DecimalType)
            #     multiply(other.to_big_decimal)
            #   elsif other.is_a?(java.math.BigDecimal)
            #     multiply(other)
            #   elsif other.respond_to?(:to_d)
            #     multiply(other.to_d.to_java)
            #   elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(to_d))
            #     lhs * rhs
            #   else
            #     raise TypeError, "#{other.class} can't be coerced into #{self.class}"
            #   end
            # end
            <<~RUBY, __FILE__, __LINE__ + 1
              def #{ruby_op}(other)
                logger.trace("\#{self} #{ruby_op} \#{other} (\#{other.class})")
                if other.is_a?(QuantityType)
                  #{java_op}_quantity(other)
                elsif other.is_a?(DecimalType)
                  #{java_op}(other.to_big_decimal)
                elsif other.is_a?(java.math.BigDecimal)
                  #{java_op}(other)
                elsif other.respond_to?(:to_d)
                  #{java_op}(other.to_d.to_java)
                elsif other.respond_to?(:coerce) && (lhs, rhs = other.coerce(to_d))
                  lhs #{ruby_op} rhs
                else
                  raise TypeError, "\#{other.class} can't be coerced into \#{self.class}"
                end
              end
            RUBY
          )
        end

        # if it's a dimensionless quantity, change the unit to match other_unit
        # @!visibility private
        def unitize(other_unit = unit)
          # prefer converting to the thread-specified unit if there is one
          other_unit = DSL.unit(dimension) || other_unit
          logger.trace("Converting #{self} to #{other_unit}")

          case unit
          when Units::ONE
            QuantityType.new(to_big_decimal, other_unit)
          when other_unit
            self
          else
            to_unit(other_unit)
          end
        end

        # if unit is {org.openhab.core.library.unit.Units.ONE}, return a plain
        # Java BigDecimal
        # @!visibility private
        def deunitize
          return to_big_decimal if unit == Units::ONE

          self
        end

        private

        # do addition directly against a QuantityType while ensuring we unitize
        # both sides
        def add_quantity(other)
          unitize(other.unit).add(other.unitize(unit))
        end

        # do subtraction directly against a QuantityType while ensuring we
        # unitize both sides
        def subtract_quantity(other)
          unitize(other.unit).subtract(other.unitize(unit))
        end

        # do multiplication directly against a QuantityType while ensuring
        # we deunitize both sides, and also invert the operation if one side
        # isn't actually a unit
        def multiply_quantity(other)
          lhs = deunitize
          rhs = other.deunitize
          # reverse the arguments if it's multiplication and the LHS isn't a QuantityType
          lhs, rhs = rhs, lhs if lhs.is_a?(java.math.BigDecimal)
          # what a waste... using a QuantityType to multiply two dimensionless quantities
          # have to make sure lhs is still a QuantityType in order to return a new
          # QuantityType that's still dimensionless
          lhs = other if lhs.is_a?(java.math.BigDecimal)

          lhs.multiply(rhs)
        end

        alias_method :divide_quantity, :divide
      end
    end
  end
end

# @!parse QuantityType = OpenHAB::Core::Types::QuantityType
