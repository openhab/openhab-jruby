# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.events.system.StartlevelEvent

      #
      # The {AbstractEvent} sent when the system start level changed.
      #
      # @!attribute [r] startlevel
      #   @return [Integer] The new start level.
      #
      class StartlevelEvent < AbstractEvent; end
    end
  end
end
