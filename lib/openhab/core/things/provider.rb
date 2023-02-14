# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      #
      # Provides {Thing Things} created in Ruby to openHAB
      #
      class Provider < Core::Provider
        include org.openhab.core.thing.ThingProvider

        class << self
          #
          # The Thing registry
          #
          # @return [org.openhab.core.thing.ThingRegistry]
          #
          def registry
            $things
          end
        end

        def initialize
          super(unload_priority: 60)
        end
      end
    end
  end
end
