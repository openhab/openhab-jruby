# frozen_string_literal: true

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
        # @param [Array<Proc>] only_if Array of Procs to use as guard
        # @param [Array<Proc>] not_if Array of Procs to use as guard
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
          return false unless check_only_if(event)
          return false unless check_not_if(event)

          true
        end

        private

        #
        # Check not_if guards
        #
        # @param [Object] event to check if meets guard
        #
        # @return [true,false] True if criteria are satisfied, false otherwise
        #
        def check_not_if(event)
          @not_if.nil? || @not_if.none? { |proc| @run_context.instance_exec(event, &proc) }
        end

        #
        # Check only_if guards
        #
        # @param [Object] event to check if meets guard
        #
        # @return [true,false] True if criteria are satisfied, false otherwise
        #
        def check_only_if(event)
          @only_if.nil? || @only_if.all? { |proc| @run_context.instance_exec(event, &proc) }
        end
      end
    end
  end
end
