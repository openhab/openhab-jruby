# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        module Conditions
          #
          # Struct capturing data necessary for a conditional trigger
          #
          class Duration
            attr_accessor :rule

            #
            # Create a new duration condition
            # @param [Object] to optional condition on to state
            # @param [Object] from optional condition on from state
            # @param [java.time.temporal.TemporalAmount] duration to state must stay at specific value before triggering
            #
            def initialize(to:, from:, duration:)
              @conditions = Generic.new(to:, from:)
              @duration = duration
              @timers = {}
              logger.trace do
                "Created Duration Condition To(#{to}) From(#{from}) " \
                  "Conditions(#{@conditions}) Duration(#{@duration})"
              end
            end

            # Process rule
            # @param [Hash] inputs inputs from trigger
            #
            def process(mod:, inputs:, &block)
              timer = @timers[inputs["triggeringItem"]&.name]
              if timer&.active?
                process_active_timer(timer, inputs, mod, &block)
              elsif @conditions.process(mod:, inputs:)
                logger.trace { "Trigger Guards Matched for #{self}, delaying rule execution" }
                # Add timer and attach timer to delay object, and also state being tracked to so
                # timer can be cancelled if state changes
                # Also another timer should not be created if changed to same value again but instead rescheduled
                create_trigger_delay_timer(inputs, mod, &block)
              else
                logger.trace { "Trigger Guards did not match for #{self}, ignoring trigger." }
              end
            end

            # Cleanup any resources from the condition
            #
            # Cancels the timer, if it's active
            def cleanup
              @timers.each_value(&:cancel)
            end

            private

            #
            # Creates a timer for trigger delays
            #
            # @param [Hash] inputs rule trigger inputs
            # @param [Hash] _mod rule trigger mods
            #
            #
            def create_trigger_delay_timer(inputs, _mod)
              logger.trace { "Creating timer for trigger delay #{self}" }
              item_name = inputs["triggeringItem"]&.name
              @timers[item_name] = DSL.after(@duration) do
                logger.trace { "Delay Complete for #{self}, executing rule" }
                @timers.delete(item_name)
                yield
              end
              rule.on_removal(self)
              @tracking_from = Conditions.old_state_from(inputs)
            end

            #
            # Process an active trigger timer
            #
            # @param [Hash] inputs rule trigger inputs
            # @param [Hash] mod rule trigger mods
            #
            def process_active_timer(timer, inputs, mod, &)
              old_state = Conditions.old_state_from(inputs)
              new_state = Conditions.new_state_from(inputs)
              if @conditions.from? && new_state != @tracking_from &&
                 @conditions.process(mod: nil, inputs: { "state" => new_state })
                logger.trace { "Item changed from #{old_state} to #{new_state} for #{self}, keep waiting." }
              else
                logger.trace { "Item changed from #{old_state} to #{new_state} for #{self}, canceling timer." }
                timer.cancel
                # Reprocess trigger delay after canceling to track new state (if guards matched, etc)
                process(mod:, inputs:, &)
              end
            end
          end
        end
      end
    end
  end
end
