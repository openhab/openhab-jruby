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
        @managed = true
        @time = time
        @id = id
        @thread_locals = thread_locals
        @block = block
        timer_identifier = block.source_location.join(":")
        @timer = ScriptExecution.create_timer(timer_identifier, 1.minute.from_now) { execute }
        reschedule!(@time)
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
      # Reschedule timer.
      #
      # If the timer had been cancelled or executed, restart the timer.
      #
      # @param [java.time.temporal.TemporalAmount, ZonedDateTime, Proc, nil] time When to reschedule the timer for.
      #   If unspecified, the original time is used.
      #
      # @return [self]
      #
      def reschedule(time = nil)
        return reschedule!(time) unless id

        # re-add ourself to the TimerManager's @timers_by_id
        DSL.timers.schedule(id) do |old_timer|
          old_timer&.cancel unless old_timer.eql?(self)
          self.id = nil
          reschedule!(time)
        end
      end

      # @return [self]
      # @!visibility private
      def reschedule!(time = nil)
        Thread.current[:openhab_rescheduled_timer] = true if Thread.current[:openhab_rescheduled_timer] == self
        DSL.timers.add(self) if managed?
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

      #
      # Returns the openHAB Timer object.
      #
      # This can be used to share the timer with other scripts via {OpenHAB::DSL.shared_cache shared_cache}.
      # The other scripts can be other JRuby scripts or scripts written in a different language
      # such as JSScripting, Python, etc. which can either be file-based or UI based scripts.
      #
      # Timers are normally managed by TimerManager, and are normally automatically cancelled
      # when the script unloads/reloads.
      #
      # To disable this automatic timer cancellation at script unload, call {unmanage}.
      #
      # openHAB will cancel the timer stored in the {OpenHAB::DSL.shared_cache shared_cache}
      # and remove the cache entry when all the scripts that _had accessed_ it have been unloaded.
      #
      # @return [org.openhab.core.automation.module.script.action.Timer]
      #
      # @see unmanage
      #
      # @example
      #   # script1.rb:
      #   timer = after(10.hours) { logger.warn "Timer created in script1.rb fired" }
      #   shared_cache[:script1_timer] = timer.to_java
      #
      #   # script2.js: (JavaScript!)
      #   rules.when().item("TestSwitch1").receivedCommand().then(event => {
      #     cache.shared.get("script1_timer")?.cancel()
      #   })
      #
      #   # or in Ruby script2.rb
      #   received_command(TestSwitch2, command: ON) do
      #     # This is an openHAB timer object, not a JRuby timer object
      #     # the reschedule method expects a ZonedDateTime
      #     shared_cache[:script1_timer]&.reschedule(3.seconds.from_now)
      #   end
      #
      # @!visibility private
      def to_java
        @timer
      end

      #
      # Removes the timer from the {TimerManager TimerManager}
      #
      # The effects of calling this method are:
      # - The timer will no longer be automatically cancelled when the script unloads.
      #   It will still execute as scheduled even if the script is unloaded/removed.
      # - It can no longer be referenced by its `id`.
      # - Subsequent calls to {OpenHAB::DSL.after after} with the same `id` will create a separate new timer.
      # - Normal timer operations such as {reschedule}, {cancel}, etc. will still work.
      #
      # @return [org.openhab.core.automation.module.script.action.Timer] The openHAB Timer object
      #
      # @example
      #   timer = after(10.hours) { logger.warn "Timer created in script1.rb fired" }
      #   shared_cache[:script1_timer] = timer
      #   # Don't cancel the timer when this script unloads,
      #   # but openHAB will do it if all scripts that had referenced the shared cache are unloaded.
      #   timer.unmanage
      #
      def unmanage
        @managed = false
        DSL.timers.delete(self)
        @id = nil
        @timer
      end

      # @return [true,false] True if the timer is managed by TimerManager, false otherwise.
      #   A timer is managed by default, and becomes un-managed when {unmanage} is called.
      def managed?
        @managed
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
