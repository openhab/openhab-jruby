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
        if key.is_a?(org.openhab.core.common.registry.Identifiable)
          return unless (provider = elementToProvider[key])

          # The HashMap lookup above uses java's hashCode() which has been overridden
          # by GenericItem and ThingImpl to return object's uid, e.g. item's name, thing uid
          # so it will return a provider even for an unmanaged object having the same uid
          # as an existing managed object.

          # So take an extra step to verify that the provider really holds the given instance.
          # by using equal? to compare the object's identity.
          # Only ManagedProviders have a #get method to look up the object by uid.
          if !provider.is_a?(org.openhab.core.common.registry.ManagedProvider) || provider.get(key.uid).equal?(key)
            provider
          end
        elsif (element = identifierToElement[key])
          elementToProvider[element]
        end
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
