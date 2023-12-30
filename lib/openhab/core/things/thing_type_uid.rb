# frozen_string_literal: true

require "forwardable"

require_relative "uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.ThingTypeUID

      #
      # {ThingTypeUID} represents a unique identifier for a {ThingType}.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] channel_group_definitions
      #   (see ThingType#channel_group_definitions)
      #
      # @!attribute [r] channel_definitions
      #   (see ThingType#channel_definitions)
      #
      # @!attribute [r] supported_bridge_type_uids
      #   (see ThingType#supported_bridge_type_uids)
      #
      # @!attribute [r] category
      #   (see ThingType#category)
      #
      # @!attribute [r] properties
      #   (see ThingType#properties)
      #
      class ThingTypeUID < UID
        extend Forwardable

        # @!method listed?
        #   @return [true, false]

        delegate %i[channel_group_definitions
                    channel_definitions
                    supported_bridge_type_uids
                    category
                    properties
                    listed?] => :thing_type

        # @!attribute [r] thing_type
        # @return [ThingType]
        def thing_type
          ThingType.registry.get_thing_type(self)
        end
      end
    end
  end
end
