# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ChannelGroupType

      #
      # {ChannelGroupType} contains a list of
      # {ChannelDefinition channel definitions} and further meta information
      # such as label and description, which are generally used by user
      # interfaces.
      #
      # @!attribute [r] uid
      #   @return [ChannelGroupTypeUID]
      #
      # @!attribute [r] channel_definitions
      #   @return [Array<ChannelDefinition>]
      #
      # @!attribute [r] category
      #   @return [String, nil]
      #
      class ChannelGroupType < AbstractDescriptionType
        class << self
          # @!visibility private
          def registry
            @registry ||= OSGi.service("org.openhab.core.thing.type.ChannelGroupTypeRegistry")
          end
        end

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::ChannelGroupType #{uid}"
          r += " category=#{category.inspect}" if category
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
