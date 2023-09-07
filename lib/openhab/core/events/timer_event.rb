# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      # @deprecated OH3.4 this guard is not needed on OH4
      if Gem::Version.new(OpenHAB::Core::VERSION) >= Gem::Version.new("4.0.0")
        java_import org.openhab.core.automation.events.TimerEvent

        #
        # Adds methods to core openHAB TimerEvent to make it more natural in Ruby
        #
        # This event can be triggered by a `DateTimeTrigger`, `cron`, or `TimeOfDay` trigger.
        #
        # @since openHAB 4.0
        #
        class TimerEvent < AbstractEvent
          #
          # @!attribute [r] cron_expression
          # @return [String, nil] The cron expression that triggered this event.
          #   `nil` when this event wasn't triggered by a cron trigger.
          #
          def cron_expression
            payload&.[](:cronExpression)
          end

          #
          # @!attribute [r] item
          # @return [Item, nil] The DateTime item that triggered this event.
          #   `nil` when this event wasn't triggered by a DateTimeItem trigger.
          #
          def item
            payload&.[](:itemName)&.then { |item_name| EntityLookup.lookup_item(item_name) }
          end

          #
          # @!attribute [r] time
          # @return [LocalTime, nil] The configured time for this TimeOfDay trigger event.
          #   `nil` when this event wasn't triggered by a TimeOfDay trigger.
          #
          def time
            payload&.[](:time)&.then { |time| LocalTime.parse(time) }
          end
        end
      end
    end
  end
end
