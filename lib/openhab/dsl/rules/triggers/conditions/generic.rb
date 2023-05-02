# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        module Conditions
          #
          # This creates trigger conditions that work on procs
          #
          class Generic
            #
            # Create a new Condition that executes only if procs return true
            # @param [#===, nil] from Value to check against `from` state
            # @param [#===, nil] to Value to check against `to` state
            # @param [#===, nil] command Value to check against received command
            #
            def initialize(from: nil, to: nil, command: nil)
              @from = from
              @to = to
              @command = command
            end

            ANY = Generic.new.freeze # this needs to be defined _after_ initialize so its instance variables are set

            #
            # Process rule
            # @param [Hash] inputs inputs from trigger
            # @return [true, false] if the conditions passed (and therefore the block was run)
            #
            def process(mod:, inputs:) # rubocop:disable Lint/UnusedMethodArgument - mod is unused here but required
              logger.trace("Checking #{inputs} against condition trigger #{self}")
              unless check_value(Conditions.old_state_from(inputs), @from) &&
                     check_value(Conditions.new_state_from(inputs), @to) &&
                     check_value(inputs["command"], @command)
                return false
              end

              yield if block_given?
              true
            end

            private

            def check_value(value, expected_value)
              return true if value.nil?

              return true if expected_value.nil?

              # works for procs, ranges, regexes, etc.
              expected_value === value # rubocop:disable Style/CaseEquality
            end
          end
        end
      end
    end
  end
end
