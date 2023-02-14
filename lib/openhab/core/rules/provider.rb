# frozen_string_literal: true

module OpenHAB
  module Core
    module Rules
      #
      # Provides rules created in Ruby to openHAB
      #
      class Provider < Core::Provider
        include org.openhab.core.automation.RuleProvider

        class << self
          #
          # The Rule registry
          #
          # @return [org.openhab.core.automation.RuleRegistry]
          #
          def registry
            $rules
          end
        end
      end
    end
  end
end
