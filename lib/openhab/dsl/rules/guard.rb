# frozen_string_literal: true

require_relative "property"

module OpenHAB
  module DSL
    module Rules
      #
      # Guard that can prevent execution of a rule if not satisfied
      #
      # @!visibility private
      class Guard
        #
        # Create a new Guard
        #
        # @param [Object] only_if Item or Proc to use as guard
        # @param [Object] not_if Item or Proc to use as guard
        #
        def initialize(run_context:, only_if: nil, not_if: nil)
          @run_context = run_context
          @only_if = only_if
          @not_if = not_if
        end

        #
        # Convert the guard into a string
        #
        # @return [String] describing the only_of and not_if guards
        #
        def to_s
          "only_if: #{@only_if}, not_if: #{@not_if}"
        end

        #
        # Checks if a guard should run
        #
        # @param [Object] event openHAB Trigger Event
        #
        # @return [true,false] True if guard is satisfied, false otherwise
        #
        def should_run?(event)
          logger.trace("Checking guards #{self}")
          check(@only_if, check_type: :only_if,
                          event: event) && check(@not_if, check_type: :not_if, event: event)
        end

        private

        #
        # Check if guard is satisfied
        #
        # @param [Array] conditions to check
        # @param [Symbol] check_type type of check to perform (:only_if or :not_if)
        # @param [Event] event openHAB event to see if it satisfies the guard
        #
        # @return [true,false] True if guard is satisfied, false otherwise
        #
        def check(conditions, check_type:, event:)
          return true if conditions.nil? || conditions.empty?

          procs, items = conditions.flatten.partition { |condition| condition.is_a?(Proc) }
          logger.trace("Procs: #{procs} Items: #{items}")

          process_check(check_type: check_type, event: event, items: items, procs: procs)
        end

        #
        # Execute the guard check
        #
        # @param [Symbol] check_type :only_if or :not_if to check
        # @param [Object] event event to check if meets guard
        # @param [Array<Item>] items to check if satisfy criteria
        # @param [Array] procs to check if satisfy criteria
        #
        # @return [true,false] True if criteria are satisfied, false otherwise
        #
        def process_check(check_type:, event:, items:, procs:)
          case check_type
          when :only_if then process_only_if(event, items, procs)
          when :not_if then  process_not_if(event, items, procs)
          else raise ArgumentError, "Unexpected check type: #{check_type}"
          end
        end

        #
        # Check not_if guard
        #
        # @param [Object] event to check if meets guard
        # @param [Array<Item>] items to check if satisfy criteria
        # @param [Array] procs to check if satisfy criteria
        #
        # @return [true,false] True if criteria are satisfied, false otherwise
        #
        def process_not_if(event, _items, procs)
          procs.none? { |proc| @run_context.instance_exec(event, &proc) }
        end

        #
        # Check only_if guard
        #
        # @param [Object] event to check if meets guard
        # @param [Array<Item>] items to check if satisfy criteria
        # @param [Array] procs to check if satisfy criteria
        #
        # @return [true,false] True if criteria are satisfied, false otherwise
        #
        def process_only_if(event, _items, procs)
          procs.all? { |proc| @run_context.instance_exec(event, &proc) }
        end
      end
    end
  end
end
