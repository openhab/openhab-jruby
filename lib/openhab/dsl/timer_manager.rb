# frozen_string_literal: true

require "set"
require "singleton"

module OpenHAB
  module DSL
    #
    # Manages timers created by {OpenHAB::DSL.after after}, or {#schedule}.
    #
    class TimerManager
      include Singleton

      Core::ScriptHandling.script_unloaded(priority: 40) { instance.cancel_all }

      # @!visibility private
      def initialize
        # Tracks active timers
        @timers = java.util.concurrent.ConcurrentHashMap.new
        @timers_by_id = java.util.concurrent.ConcurrentHashMap.new
      end

      #
      # Create a new timer, managing ids if necessary
      #
      # @!visibility private
      def create(duration, thread_locals:, block:, id:, reschedule:)
        if id
          return @timers_by_id.compute(id) do |_key, old_timer|
            # return the existing timer if we're only supposed to create a new
            # timer when one doesn't already exist
            next old_timer if !reschedule && old_timer

            if old_timer
              old_timer.cancel!
              @timers.remove(old_timer)
            end
            Core::Timer.new(duration, id: id, thread_locals: thread_locals, block: block)
          end
        end

        Core::Timer.new(duration, id: id, thread_locals: thread_locals, block: block)
      end

      # Add a timer that is now active
      # @!visibility private
      def add(timer)
        logger.trace("Adding #{timer} to timers")
        @timers[timer] = 1
      end

      #
      # Delete a timer that is no longer active
      #
      # @!visibility private
      def delete(timer)
        logger.trace("Removing #{timer} from timers")
        @timers.remove(timer)
        return unless timer.id

        @timers_by_id.remove(timer.id)
      end

      #
      # Cancel a single timer by id
      #
      # @param [Object] id
      # @return [true, false] if the timer was able to be cancelled
      #
      def cancel(id)
        result = false
        @timers_by_id.compute_if_present(id) do |_key, timer|
          result = timer.cancel!
          @timers.remove(timer)

          nil
        end
        result
      end

      #
      # Reschedule a single timer by id
      #
      # @param [Object] id
      # @param [java.time.temporal.TemporalAmount, #to_zoned_date_time, Proc, nil] duration
      #   When to reschedule the timer for. `nil` to retain its current interval.
      # @return [Timer, nil] the timer if it was rescheduled, otherwise `nil`
      #
      def reschedule(id, duration = nil)
        @timers_by_id.compute_if_present(id) do |_key, timer|
          timer.reschedule(duration)
        end
      end

      #
      # Schedule a timer by id
      #
      # Schedules a timer by id, but passes the current timer -- if it exists --
      # to the block so that you can decide how you want to proceed based on that
      # state. The timer is created in a thread-safe manner.
      #
      # @param [Object] id
      # @yieldparam [Timer, nil] timer The existing timer with this id, if one exists.
      # @yieldreturn [Timer, nil] A new timer to associate with this id, the existing
      #   timer, or nil. If nil, any existing timer will be cancelled.
      # @return [Timer, nil]
      #
      # @example Extend an existing timer, or schedule a new one
      #   # This is technically the same functionality as just calling `after()` with an `id`,
      #   # but allows you to performa extra steps if the timer is actually scheduled.
      #   timers.schedule(item) do |timer|
      #     next timer.tap(&:reschedule) if timer
      #
      #     notify("The lights were turned on")
      #
      #     after(30.seconds) { item.off }
      #   end
      #
      # @example Keep trying to turn something on, up to 5 times
      #   timers.schedule(item) do |timer|
      #     next if timer # don't interrupt a retry cycle if it already exists
      #
      #     retries = 5
      #     after(2.seconds) do |inner_timer|
      #       next if (retries -= 1).zero?
      #       next inner_timer.reschedule unless item.on?
      #
      #       item.on
      #     end
      #   end
      #
      def schedule(id)
        @timers_by_id.compute(id) do |_key, timer|
          new_timer = yield timer
          raise ArgumentError, "Block must return a timer or nil" unless new_timer.is_a?(Core::Timer) || new_timer.nil?

          if !new_timer.equal?(timer) && new_timer&.id
            raise ArgumentError,
                  "Do not schedule a new timer with an ID inside a #schedule block"
          end

          if timer&.cancelled?
            new_timer = nil
          elsif new_timer.nil? && timer && !timer.cancelled?
            timer.cancel!
            @timers.remove(timer)
          end
          next unless new_timer

          new_timer.id ||= id
          if new_timer.id != id
            raise ArgumentError,
                  "The new timer cannot have a different ID than what you're attempting to schedule"
          end

          new_timer
        end
      end

      #
      # Checks if a timer exists by id
      #
      # @note This method is not recommended for normal use in rules.
      #   Timers are prone to race conditions if accessed from multiple rules,
      #   or from timers themselves. Rescheduling, canceling, or scheduling
      #   a new timer based on the results of this method may cause problems,
      #   since the state may have changed in the meantime. Instead, use
      #   {OpenHAB::DSL.after after} with an `id`, {#cancel}, {#reschedule}, or
      #   {#schedule} to perform those actions atomically.
      #
      # @param [Object] id
      # @return [true, false]
      #
      def include?(id)
        @timers_by_id.key?(id)
      end
      alias_method :key?, :include?
      alias_method :member?, :include?

      #
      # Cancels all active timers in the current script/UI rule
      #
      # Including timers with or without an id.
      #
      # @return [void]
      #
      def cancel_all
        logged = false
        # don't use #each, in case timers are scheduling more timers
        until @timers.empty?
          logger.trace("Canceling #{@timers.length} timers") unless logged
          logged = true
          timer = @timers.keys.first
          timer.cancel
        end
      end
    end
  end
end
