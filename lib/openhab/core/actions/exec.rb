# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # @see https://www.openhab.org/docs/configuration/actions.html#exec-actions Exec Actions
      class Exec # rubocop:disable Lint/EmptyClass
        # @!scope class

        # @!method execute_command_line
        #
        # @return [void]
        #
        # @overload execute_command_line(command_line)
        #
        #   Executes a command on the command line without waiting for the
        #   command to complete.
        #
        #   @param [String] command_line
        #   @return [void]
        #
        #   @example Execute an external command
        #     rule 'Run a command' do
        #       every :day
        #       run do
        #         Exec.execute_command_line('/bin/true')
        #       end
        #     end
        #
        # @overload execute_command_line(timeout, command_line)
        #
        #   Executes a command on the command and waits timeout seconds for
        #   the command to complete, returning the output from the command
        #   as a String.
        #
        #   @param [Duration] timeout
        #   @param [String] command_line
        #   @return [String]
        #
        #   @example Execute an external command and process its results
        #     rule 'Run a command' do
        #       every :day
        #       run do
        #         TodaysHoliday_String.update(Exec.execute_command_line(5.seconds, '/home/cody/determine_holiday.rb')
        #       end
        #     end
        #
      end
    end
  end
end
