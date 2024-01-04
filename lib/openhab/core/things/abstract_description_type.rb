# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.AbstractDescriptionType

      #
      # Base class for {ThingType}, {ChannelType}, and {ChannelGroupType}
      #
      # @!attribute [r] label
      #   @return [String]
      #
      # @!attribute [r] description
      #   @return [String, nil]
      #
      class AbstractDescriptionType # rubocop:disable Lint/EmptyClass
      end
    end
  end
end
