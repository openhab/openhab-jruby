# frozen_string_literal: true

require_relative "type"

module OpenHAB
  module Core
    module Types
      PointType = org.openhab.core.library.types.PointType

      # {PointType} can be used for items that are dealing with GPS or location awareness functionality.
      class PointType
        # @!parse include Command, State

        # @overload initialize(latitude, longitude, altitude)
        #   @param [DecimalType, QuantityType, StringType, Numeric] latitude
        #   @param [DecimalType, QuantityType, StringType, Numeric] longitude
        #   @param [DecimalType, QuantityType, StringType, Numeric] altitude
        def initialize(*args)
          if (2..3).cover?(args.length)
            args = args.each_with_index.map do |value, index|
              if value.is_a?(DecimalType) || value.is_a?(StringType)
                value
              elsif value.is_a?(QuantityType)
                unit = (index == 2) ? DSL.unit(SIUnits::METRE.dimension) || SIUnits::METRE : Units::DEGREE_ANGLE
                DecimalType.new(value.to_unit(unit).to_big_decimal)
              elsif value.respond_to?(:to_str)
                StringType.new(value.to_str)
              elsif value.respond_to?(:to_d)
                DecimalType.new(value)
              end
            end
          end

          super
        end

        #
        # Check equality without type conversion
        #
        # @return [true,false] if the same value is represented, without type
        #   conversion
        def eql?(other)
          return false unless other.instance_of?(self.class)

          equals(other)
        end

        #
        # Check equality with type conversion
        #
        # @param [PointType, String]
        #   other object to compare to
        #
        # @return [true,false]
        #
        def ==(other)
          logger.trace { "(#{self.class}) #{self} == #{other} (#{other.class})" }
          if other.instance_of?(self.class)
            equals(other)
          elsif other.respond_to?(:coerce)
            return false unless (lhs, rhs = other.coerce(self))

            lhs == rhs
          end
        end

        # rename raw methods so we can overwrite them
        # @!visibility private
        alias_method :raw_latitude, :latitude
        # .
        # @!visibility private
        alias_method :raw_longitude, :longitude
        # .
        # @!visibility private
        alias_method :raw_altitude, :altitude
        # .
        # @!visibility private
        alias_method :raw_distance_from, :distance_from

        # @!attribute [r] latitude
        # @return [QuantityType]
        def latitude
          QuantityType.new(raw_latitude.to_big_decimal, Units::DEGREE_ANGLE)
        end

        # @!attribute [r] longitude
        # @return [QuantityType]
        def longitude
          QuantityType.new(raw_longitude.to_big_decimal, Units::DEGREE_ANGLE)
        end

        # @!attribute [r] altitude
        # @return [QuantityType]
        def altitude
          QuantityType.new(raw_altitude.to_big_decimal, SIUnits::METRE)
        end

        #
        # Calculate the distance in meters from other, ignoring altitude.
        #
        # This algorithm also ignores the oblate spheroid shape of Earth and
        # assumes a perfect sphere, so results are inexact.
        #
        # @return [QuantityType]
        def distance_from(other)
          logger.trace { "(#{self}).distance_from(#{other} (#{other.class})" }
          raise TypeError, "#{other.class} can't be coerced into #{self.class}" unless other.is_a?(PointType)

          QuantityType.new(raw_distance_from(other), SIUnits::METRE)
        end
        alias_method :-, :distance_from
      end
    end
  end
end

# @!parse PointType = OpenHAB::Core::Types::PointType
