# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        module Conditions
          class << self
            # If a given value can be passed directly to openHAB's trigger handler configuration
            # @return [true, false]
            def state?(value)
              value.nil? ||
                value.is_a?(Core::Types::Type) ||
                value.is_a?(String) ||
                value.is_a?(Symbol) ||
                value.is_a?(Numeric)
            end

            # Retrieves the previous item state or things status from inputs
            # @return [Core::Types::Type, Symbol, nil]
            def old_state_from(inputs)
              inputs["oldState"] || inputs["oldStatus"]&.to_s&.downcase&.to_sym
            end

            # Retrieves the new item state or thing status from inputs
            # @return [Core::Types::Type, Symbol, nil]
            def new_state_from(inputs)
              inputs["newState"] || inputs["state"] || inputs["newStatus"]&.to_s&.downcase&.to_sym
            end
          end
        end
      end
    end
  end
end
