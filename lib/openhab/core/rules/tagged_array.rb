# frozen_string_literal: true

require "singleton"

module OpenHAB
  module Core
    module Rules
      #
      # Provides access to a set of openHAB {Rule rules}, and acts like an array.
      #
      class TaggedArray
        include LazyArray

        def initialize(tag)
          @tag = tag
        end

        #
        # Gets a specific Rule
        #
        # @param [String] uid Rule UID
        # @return [Rule, nil]
        #
        def [](uid)
          rule = $rules.get(uid)
          rule.tagged?(@tag) ? rule : nil
        end
        alias_method :include?, :[]
        alias_method :key?, :[]
        # @deprecated
        alias_method :has_key?, :[]

        #
        # Explicit conversion to array
        #
        # @return [Array<Rule>]
        #
        def to_a
          $rules.all.to_a.tagged(@tag)
        end
      end
    end
  end
end
