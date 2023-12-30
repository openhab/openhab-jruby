# frozen_string_literal: true

require_relative "uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.ThingUID

      #
      # {ThingUID} represents a unique identifier for a {Thing}.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] bridge_ids
      #   @return [Array<string>]
      #
      class ThingUID < UID
        extend Forwardable

        # @!attribute [r] thing
        # @return [Thing]
        def thing
          EntityLookup.lookup_thing(self)
        end
      end
    end
  end
end
