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
              to = Conditions::Proc.from_value(to)
              from = Conditions::Proc.from_value(from)
              @conditions = Conditions::Proc.new(to: to, from: from)
              @duration = duration
              @timer = nil
              logger.trace "Created Duration Condition To(#{to}) From(#{from}) " \
                           "Conditions(#{@conditions}) Duration(#{@duration})"
            end

            # Process rule
            # @param [Hash] inputs inputs from trigger
            #
            def process(mod:, inputs:, &block)
              if @timer&.active?
                process_active_timer(inputs, mod, &block)
              elsif check_trigger_guards(inputs)
                logger.trace("Trigger Guards Matched for #{self}, delaying rule execution")
                # Add timer and attach timer to delay object, and also state being tracked to so
                # timer can be cancelled if state changes
                # Also another timer should not be created if changed to same value again but instead rescheduled
                create_trigger_delay_timer(inputs, mod, &block)
              else
                logger.trace("Trigger Guards did not match for #{self}, ignoring trigger.")
              end
            end

            # Cleanup any resources from the condition
            #
            # Cancels the timer, if it's active
            def cleanup
              @timer&.cancel
            end

            private

            #
            # Check if trigger guards prevent rule execution
            #
            # @param [java.util.Map] inputs map object describing rule trigger
            #
            # @return [true,false] True if the rule should execute, false if trigger guard prevents execution
            #
            def check_trigger_guards(inputs)
              new_state, old_state = retrieve_states(inputs)
              @conditions.check_from(state: old_state) && @conditions.check_to(state: new_state)
            end

            #
            # Rerieve the newState and oldState, alternatively newStatus and oldStatus
            # from the input map
            #
            # @param [java.util.Map] inputs map object describing rule trigger
            #
            # @return [Array] An array of the values for [newState, oldState] or [newStatus, oldStatus]
            #
            def retrieve_states(inputs)
              new_state = inputs["newState"] || inputs["newStatus"]&.to_s&.downcase&.to_sym
              old_state = inputs["oldState"] || inputs["oldStatus"]&.to_s&.downcase&.to_sym

              [new_state, old_state]
            end

            #
            # Creates a timer for trigger delays
            #
            # @param [Hash] inputs rule trigger inputs
            # @param [Hash] _mod rule trigger mods
            #
            #
            def create_trigger_delay_timer(inputs, _mod)
              logger.trace("Creating timer for trigger delay #{self}")
              @timer = DSL.after(@duration) do
                logger.trace("Delay Complete for #{self}, executing rule")
                @timer = nil
                yield
              end
              rule.on_removal(self)
              _, @tracking_from = retrieve_states(inputs)
            end

            #
            # Process an active trigger timer
            #
            # @param [Hash] inputs rule trigger inputs
            # @param [Hash] mod rule trigger mods
            #
            def process_active_timer(inputs, mod, &block)
              new_state, old_state = retrieve_states(inputs)
              if new_state != @tracking_from && @conditions.check_to(inputs: {})
                logger.trace("Item changed from #{old_state} to #{new_state} for #{self}, keep waiting.")
              else
                logger.trace("Item changed from #{old_state} to #{new_state} for #{self}, canceling timer.")
                @timer.cancel
                # Reprocess trigger delay after canceling to track new state (if guards matched, etc)
                process(mod: mod, inputs: inputs, &block)
              end
            end
          end
        end
      end
    end
  end
end
