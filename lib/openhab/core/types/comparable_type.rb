# frozen_string_literal: true

require_relative "type"

module OpenHAB
  module Core
    # `Comparable#==` is overwritten by Type, because {DecimalType} etc.
    # inherit from `Comparable` on the Java side, so it's in the wrong place
    # in the ancestor list
    # @!visibility private
    module ComparableType
      # re-implement
      # @!visibility private
      def ==(other)
        r = self <=> other

        return false if r.nil?

        r.zero?
      end
    end
  end
end
