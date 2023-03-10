# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"
require "forwardable"

require_relative "type"

module OpenHAB
  module Core
    module Types
      # Mixin for methods common to DecimalType and QuantityType.
      module NumericType
        # @!visibility private
        def self.included(klass)
          klass.extend Forwardable

          klass.delegate %i[to_d zero?] => :to_big_decimal
          klass.delegate %i[positive? negative? to_f to_i to_int hash] => :to_d

          # remove the JRuby default == so that we can inherit the Ruby method
          klass.remove_method :==
        end

        #
        # Check equality without type conversion
        #
        # @return [true,false] if the same value is represented, without type
        #   conversion
        def eql?(other)
          return false unless other.instance_of?(self.class)

          compare_to(other).zero?
        end

        # @return [self]
        def +@
          self
        end

        # @!method to_d
        #   @return [BigDecimal]

        # @!method to_i
        #   @return [Integer]

        # @!method to_f
        #   @return [Float]
      end
    end
  end
end
