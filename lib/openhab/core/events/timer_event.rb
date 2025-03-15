# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
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
        # @!attribute [r] time_only?
        # @return [Boolean]
        #   `true` when this event was triggered by a {Core::Items::DateTimeItem DateTimeItem} with `timeOnly` set.
        #   `false` when this event wasn't triggered by a DateTimeItem or the `timeOnly` flag is not set.
        # @see DSL::Rules::BuilderDSL::every #every trigger
        # @see DSL::Rules::BuilderDSL::at #at trigger
        # @since openHAB 4.3
        #
        def time_only?
          !!payload&.[](:timeOnly)
        end

        #
        # @!attribute [r] offset
        # @return [Duration, nil] The offset from the configured time for this DateTime trigger event.
        #   `nil` when this event wasn't triggered by a DateTime trigger.
        # @since openHAB 4.3
        #
        def offset
          payload&.[](:offset)&.seconds
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
