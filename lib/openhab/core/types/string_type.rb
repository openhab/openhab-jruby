# frozen_string_literal: true

require "forwardable"

require_relative "comparable_type"
require_relative "type"

module OpenHAB
  module Core
    module Types
      StringType = org.openhab.core.library.types.StringType

      # {StringType} represents a String as a {Type} and a {Command}.
      class StringType
        # @!parse include Command, State

        extend Forwardable
        include Comparable
        include ComparableType

        #
        # Check equality without type conversion
        #
        # @return [true,false] if the same value is represented, without type
        #   conversion
        def eql?(other)
          return false unless other.instance_of?(self.class)

          to_s.compare_to(other.to_s).zero?
        end

        #
        # Comparison
        #
        # @param [StringType, String]
        #   other object to compare to
        #
        # @return [Integer, nil] -1, 0, +1 depending on whether `other` is
        #   less than, equal to, or greater than self
        #
        #   `nil` is returned if the two values are incomparable.
        #
        def <=>(other)
          logger.trace("(#{self.class}) #{self} <=> #{other} (#{other.class})")
          if other.respond_to?(:to_str)
            to_str <=> other.to_str
          elsif other.respond_to?(:coerce)
            return nil unless (lhs, rhs = other.coerce(self))

            lhs <=> rhs
          end
        end

        #
        # Type Coercion
        #
        # Coerce object to a StringType
        #
        # @param [String] other object to coerce to a
        #   DateTimeType
        #
        # @return [[StringType, StringType], nil]
        #
        def coerce(other)
          logger.trace("Coercing #{self} as a request from #{other.class}")
          return [other.to_str, self] if other.respond_to?(:to_str)
        end

        # any method that exists on String gets forwarded to to_s
        delegate (String.instance_methods - instance_methods + %w[=~ inspect]) => :to_s
      end
    end
  end
end

# @!parse StringType = OpenHAB::Core::Types::StringType
