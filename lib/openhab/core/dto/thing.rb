# frozen_string_literal: true

module OpenHAB
  module Core
    module DTO
      java_import org.openhab.core.thing.dto.AbstractThingDTO

      # Adds methods to core openHAB AbstractThingDTO to make it more natural in Ruby
      class AbstractThingDTO
        # @!attribute [r] uid
        # The thing's UID
        # @return [String]
        alias_method :uid, :UID

        # @!attribute [r] thing_type_uid
        # The thing type's UID
        # @return [String]
        alias_method :thing_type_uid, :thingTypeUID

        # @!attribute [r] bridge_uid
        # The Bridge's UID
        # @return [String, nil]
        alias_method :bridge_uid, :bridgeUID
      end
    end
  end
end
