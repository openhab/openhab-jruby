# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    #
    # Timer allows you to administer the block of code that
    # has been scheduled to run later with {OpenHAB::DSL.after after}.
    #
    class Timer
      extend Forwardable

      # @!method active?
      #   Check if the timer will execute in the future.
      #   @return [true,false]

      # @!method cancelled?
      #   Check if the timer has been cancelled.
      #   @return [true,false]

      # @!method running?
      #   Check if the timer code is currently running.
      #   @return [true,false]

      # @!method terminated?
      #   Check if the timer has terminated.
      #   @return [true,false]

      def_delegator :@timer, :has_terminated, :terminated?
      def_delegators :@timer, :active?, :cancelled?, :running?, :execution_time

      # @return [Object, nil]
      attr_accessor :id

      # @!visibility private
      attr_reader :block

      #
      # Create a new Timer Object
      #
      # @param [java.time.temporal.TemporalAmount, #to_zoned_date_time, Proc] time When to execute the block
      # @yield Block to execute when timer fires
      # @yieldparam [self]
      #
      # @!visibility private
      def initialize(time, id:, thread_locals:, block:)
        @time = time
        @id = id
        @thread_locals = thread_locals
        @block = block
        @timer = ScriptExecution.create_timer(1.minute.from_now) { execute }
        reschedule(@time)
      end

      # @return [String]
      def inspect
        r = "#<#{self.class.name} #{"#{id.inspect} " if id}#{block.source_location.join(":")}"
        if cancelled?
          r += " (cancelled)"
        else
          r += " @ #{execution_time}"
          r += " (executed)" if terminated?
        end
        "#{r}>"
      end
      alias_method :to_s, :inspect

      # @!attribute [r] execution_time
      #   @return [ZonedDateTime, nil] the scheduled execution time, or `nil` if the timer was cancelled

      #
      # Reschedule timer
      #
      # @param [java.time.temporal.TemporalAmount, ZonedDateTime, Proc, nil] time When to reschedule the timer for.
      #   If unspecified, the original time is used.
      #
      # @return [self]
      #
      def reschedule(time = nil)
        Thread.current[:openhab_rescheduled_timer] = true if Thread.current[:openhab_rescheduled_timer] == self
        DSL.timers.add(self)
        @timer.reschedule(new_execution_time(time || @time))
        self
      end

      #
      # Cancel timer
      #
      # @return [true,false] True if cancel was successful, false otherwise
      #
      def cancel
        DSL.timers.delete(self)
        cancel!
      end

      #
      # Cancel the timer but do not remove self from the timer manager
      #
      # To be used internally by {TimerManager} from inside ConcurrentHashMap's compute blocks
      #
      # @return [true,false] True if cancel was successful, false otherwise
      #
      # @!visibility private
      def cancel!
        @timer.cancel
      end

      private

      #
      # Calls the block with thread locals set up, and cleans up after itself
      #
      # @return [void]
      #
      def execute
        Thread.current[:openhab_rescheduled_timer] = self
        DSL::ThreadLocal.thread_local(**@thread_locals) { @block.call(self) }
        DSL.timers.delete(self) unless Thread.current[:openhab_rescheduled_timer] == true
        Thread.current[:openhab_rescheduled_timer] = nil
      end

      #
      # @return [ZonedDateTime]
      #
      def new_execution_time(time)
        time = time.call if time.is_a?(Proc)
        time = time.from_now if time.is_a?(java.time.temporal.TemporalAmount)
        time.to_zoned_date_time
      end
    end
  end
end
