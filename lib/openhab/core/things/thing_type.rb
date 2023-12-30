# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ThingType

      #
      # {ThingType} contains a list of
      # {ChannelGroupDefinition channel group definitions},
      # {ChannelDefinition channel definitions} and further meta information.
      #
      # This description is used as template definition for the creation of the
      # according concrete {Thing} object.
      #
      # @!attribute [r] uid
      #   @return [ChannelGroupTypeUID]
      #
      # @!attribute [r] channel_group_definitions
      #   @return [Array<ChannelGroupDefinition>]
      #
      # @!attribute [r] channel_definitions
      #   @return [Array<ChannelDefinition>]
      #
      # @!attribute [r] supported_bridge_type_uids
      #   @return [Array<String>]
      #
      # @!attribute [r] category
      #   @return [String, nil]
      #
      # @!attribute [r] properties
      #   @return [Hash<String, String>]
      #
      class ThingType < AbstractDescriptionType
        class << self
          # @!visibility private
          def registry
            @registry ||= OSGi.service("org.openhab.core.thing.type.ThingTypeRegistry")
          end
        end

        # @!attribute [r] listed?
        # @return [true, false]
        alias_method :listed?, :is_listed

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::ThingType #{uid}"
          r += " (unlisted)" unless listed?
          r += " category=#{category.inspect}" if category
          r += " properties=#{properties.to_h}" unless properties.empty?
          "#{r}>"
        end

        # @return [String]
        def to_s
          uid.to_s
        end
      end
    end
  end
end
