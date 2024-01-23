# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Items
      # Mixin for implementing type coercion for number-like items
      module NumericItem
        %i[positive? negative? zero? nonzero?].each do |predicate|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{predicate}              # def positive?
              return false unless state?  #   return false unless state?
                                          #
              state.#{predicate}          #   state.positive?
            end                           # end
          RUBY
        end
      end
    end
  end
end
