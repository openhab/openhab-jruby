# frozen_string_literal: true

module OpenHAB
  module Core
    Registry = org.openhab.core.common.registry.AbstractRegistry

    Registry.field_reader :elementToProvider, :elementReadLock, :identifierToElement

    # @abstract
    #
    # The base class for all registries in openHAB.
    #
    class Registry
      #
      # Determines which provider an element is associated with.
      #
      # @param [Object] key
      # @return [org.openhab.core.common.registry.Provider]
      #
      def provider_for(key)
        elementReadLock.lock
        if key.is_a?(org.openhab.core.common.registry.Identifiable)
          element = key
        else
          return nil unless (element = identifierToElement[key])
        end

        elementToProvider[element]
      ensure
        elementReadLock.unlock
      end
    end
  end
end
