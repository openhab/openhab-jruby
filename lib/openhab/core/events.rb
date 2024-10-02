# frozen_string_literal: true

module OpenHAB
  module Core
    # Contains objects sent to event handlers containing context around the
    # triggered event.
    module Events
      class << self
        # @!visibility private
        def publisher
          @publisher ||= OSGi.service("org.openhab.core.events.EventPublisher")
        end
      end

      java_import org.openhab.core.items.events.ItemEventFactory
    end
  end
end
