# frozen_string_literal: true

module OpenHAB
  module Core
    #
    # Contains the core {Rule} as well as related infrastructure.
    #
    module Rules
      java_import org.openhab.core.automation.RuleStatus,
                  org.openhab.core.automation.RuleStatusInfo,
                  org.openhab.core.automation.RuleStatusDetail,
                  org.openhab.core.automation.Visibility

      class << self
        #
        # @!attribute [r] manager
        # @return [org.openhab.core.automation.RuleManager] The openHAB rule manager/engine
        #
        def manager
          @manager ||= OSGi.service("org.openhab.core.automation.RuleManager")
        end
      end
    end
  end
end
