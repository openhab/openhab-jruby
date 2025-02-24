# frozen_string_literal: true

module OpenHAB
  module Core
    Registry = org.openhab.core.common.registry.AbstractRegistry

    Registry.field_reader :elementToProvider, :elementReadLock, :identifierToElement, :providerToElements

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
        element = key.is_a?(org.openhab.core.common.registry.Identifiable) ? key : identifierToElement[key]
        elementToProvider[element] if element
      ensure
        elementReadLock.unlock
      end

      # @!attribute [r] providers
      # @return [Enumerable<org.openhab.core.common.registry.Provider>]
      def providers
        providerToElements.keys
      end
    end
  end
end
