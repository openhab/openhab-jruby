# frozen_string_literal: true

require "singleton"

module OpenHAB
  module Core
    module Things
      #
      # Provides access to all openHAB {Thing things}, and acts like an array.
      #
      class Registry
        include LazyArray
        include Singleton

        #
        # Gets a specific {Thing}
        #
        # @param [String, ThingUID] uid Thing UID in the format `binding_id:type_id:thing_id`
        #   or via the ThingUID
        # @return [Thing, nil]
        #
        def [](uid)
          EntityLookup.lookup_thing(uid)
        end
        alias_method :include?, :[]
        alias_method :key?, :[]
        # @deprecated
        alias_method :has_key?, :[]

        #
        # Explicit conversion to array
        #
        # @return [Array<Thing>]
        #
        def to_a
          $things.all.map { |thing| Proxy.new(thing) }
        end

        #
        # Enter the Thing Builder DSL.
        # @param (see Core::Provider.current)
        # @yield Block executed in the context of a {DSL::Things::Builder}.
        # @return [Object] The result of the block.
        #
        def build(preferred_provider = nil, &block)
          DSL::Things::Builder.new(preferred_provider).instance_eval(&block)
        end

        #
        # Remove a Thing.
        #
        # The thing must be a managed thing (typically created by Ruby or in the UI).
        #
        # @param [String, Thing, ThingUID] thing_uid
        # @return [Thing, nil] The removed item, if found.
        def remove(thing_uid)
          thing_uid = thing.uid if thing_uid.is_a?(Thing)
          thing_uid = ThingUID.new(thing_uid) if thing_uid.is_a?(String)
          provider = Provider.registry.provider_for(thing_uid)
          unless provider.is_a?(org.openhab.core.common.registry.ManagedProvider)
            raise "Cannot remove thing #{thing_uid} from non-managed provider #{provider.inspect}"
          end

          Links::Provider.registry.providers.grep(ManagedProvider).each do |managed_provider|
            managed_provider.remove_links_for_thing(thing_uid)
          end

          provider.remove(thing_uid)
        end
      end
    end
  end
end
