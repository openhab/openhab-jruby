# frozen_string_literal: true

module OpenHAB
  module DSL
    #
    # Provides the feature for debouncing calls to a given block.
    #
    # The debouncer can filter events and only allow the events on the leading or trailing edge
    # of the given interval. Its behavior can be customized through settings passed to its
    # {initialize constructor}.
    #
    # The following timing diagram illustrates the incoming triggers and the actual executions
    # using various options.
    #
    # ```ruby
    #                              1    1    2    2    3    3    4    4
    #                    0    5    0    5    0    5    0    5    0    5
    # Triggers        : 'X.X...X...X..XX.X.X......XXXXXXXXXXX....X.....'
    # leading: false
    # for:5           : '|....X|....X |....X      |....X|....X   |....X'
    # leading: true
    # for:5           : 'X.....X......X....X......X....X....X....X.....'
    #
    # more options, leading: false
    # Triggers        : 'X.X...X...X..XX.X.X......XXXXXXXXXXX....X.....'
    # for:5 idle:3    : '|....X|......X|......X...|............X.|....X'
    # for:5 idle:5    : '|......................X.|..............X.....'
    # for:5..5 idle:X : '|....X|....X.|....X......|....X|....X...|....X'
    # for:5..6 idle:5 : '|.....X...|.....X.|....X.|.....X|.....X.|....X'
    # for:5..7 idle:5 : '|......X..|......X|....X.|......X|......X.....'
    # for:5..8 idle:5 : '|.......X.|.......X......|.......X|.....X.....'
    # for:5..8 idle:3 : '|....X|......X|......X...|.......X|....X|....X'
    # for:5..8 idle:2 : '|....X|.....X|......X....|.......X|....X|....X'
    # ```
    #
    # Notes:
    # - `|` indicates the start of the debounce period
    # - With `for: 5..5` (a range with begin=end), the `idle_time` argument is irrelevant
    #   and be unset/set to any value as it will not alter the debouncer's behavior.
    # - Without an `idle_time`, the range end in `for: X..Y` is irrelevant. It is equivalent to
    #   `for: X` without the end of the range.
    #
    class Debouncer
      # @return [Range,nil] The range of accepted debounce period, or nil if debouncing is disabled.
      attr_reader :interval

      # @return [Duration, nil] The minimum idle time to stop debouncing.
      attr_reader :idle_time

      #
      # Constructor to create a debouncer object.
      #
      # The constructor sets the options and behaviour of the debouncer when the {#call}
      # method is called.
      #
      # Terminology:
      # - `calls` are invocations of the {#call} method, i.e. the events that need to be throttled / debounced.
      # - `executions` are the actual code executions of the given block. Executions usually occur
      #   less frequently than the call to the debounce method.
      #
      # @param [Duration,Range,nil] for The minimum and optional maximum execution interval.
      #   - {Duration}: The minimum interval between executions. The debouncer will not execute
      #     the given block more often than this.
      #   - {Range}: A range of {Duration}s for the minimum to maximum interval between executions.
      #     The range end defines the maximum duration from the initial trigger, at which
      #     the debouncer will execute the block, even when an `idle_time` argument was given and
      #     calls continue to occur at an interval less than `idle_time`.
      #   - `nil`: When `nil`, no debouncing is performed, all the other parameters are ignored,
      #     and every call will result in immediate execution of the given block.
      #
      # @param [true,false] leading
      #   - `true`: Perform leading edge "debouncing". Execute the first call then ignore
      #     subsequent calls that occur within the debounce period.
      #   - `false`: Perform trailing edge debouncing. Execute the last call at the end of
      #     the debounce period and ignore all the calls leading up to it.
      #
      # @param [Duration,nil] idle_time The minimum idle time between calls to stop debouncing.
      #   The debouncer will continue to hold until the interval between two calls is longer
      #   than the idle time or until the maximum interval between executions, when
      #   specified, is reached.
      #
      # @return [void]
      #
      def initialize(for:, leading: false, idle_time: nil)
        @interval = binding.local_variable_get(:for)
        return unless @interval

        @interval = (@interval..) unless @interval.is_a?(Range)

        @leading = leading
        @idle_time = idle_time
        @mutex = Mutex.new
        @block = nil
        @timer = nil
        reset
      end

      #
      # Debounces calls to the given block.
      #
      # This method is meant to be called repeatedly with the same given block.
      # However, if no block is given, it will call and debounce the previously given block
      #
      # @yield Block to be debounced
      #
      # @return [void]
      #
      # @example Basic trailing edge debouncing
      #   debouncer = Debouncer.new(for: 1.minute)
      #   (1..100).each do
      #     debouncer.call { logger.info "I won't log more often than once a minute" }
      #     sleep 20 # call the debouncer every 20 seconds
      #   end
      #
      # @example Call the previous debounced block
      #   debouncer = Debouncer.new(for: 1.minute)
      #   debouncer.call { logger.info "Hello. It is #{Time.now}" } # First call to debounce
      #
      #   after(20.seconds) do |timer|
      #     debouncer.call # Call the original block above
      #     timer.reschedule unless timer.cancelled?
      #   end
      #
      def call(&block)
        @block = block if block
        raise ArgumentError, "No block has been provided" unless @block

        return call! unless @interval # passthrough mode, no debouncing when @interval is nil

        now = ZonedDateTime.now
        if leading?
          leading_edge_debounce(now)
        else
          trailing_edge_debounce(now)
        end
        @mutex.synchronize { @last_timestamp = now }
      end

      #
      # Executes the latest block passed to the {#debounce} call regardless of any debounce settings.
      #
      # @return [Object] The return value of the block
      #
      def call!
        @block.call
      end

      #
      # Resets the debounce period and cancels any outstanding block executions of a trailing edge debouncer.
      #
      # - A leading edge debouncer will execute its block on the next call and start a new debounce period.
      # - A trailing edge debouncer will reset its debounce timer and the next call will become the start
      #   of a new debounce period.
      #
      # @return [Boolean] True if a pending execution was cancelled.
      #
      def reset
        @mutex.synchronize do
          @last_timestamp = @leading_timestamp = @interval.begin.ago - 1.second if leading?
          @timer&.cancel
        end
      end

      #
      # Immediately executes any outstanding event of a trailing edge debounce.
      # The next call will start a new period.
      #
      # It has no effect on a leading edge debouncer - use {#reset} instead.
      #
      # @return [Boolean] True if an existing debounce timer was rescheduled to run immediately.
      #   False if there were no outstanding executions.
      #
      def flush
        @mutex.synchronize do
          if @timer&.cancel
            call!
            true
          end
        end
      end

      #
      # Returns true to indicate that this is a leading edge debouncer.
      #
      # @return [true,false] True if this object was created to be a leading edge debouncer. False otherwise.
      #
      def leading?
        @leading
      end

      private

      def too_soon?(now)
        now < @leading_timestamp + @interval.begin
      end

      # @return [true,false] When max interval is not set/required, always returns false,
      #   because there is no maximum interval requirement.
      #   When it is set, return true if the max interval condition is met, or false otherwise
      def max_interval?(now)
        @interval.end && now >= @leading_timestamp + @interval.end
      end

      # @return [true,false] When idle_time is not set/required, always returns true,
      #   as if the idle time condition is met.
      #   When it is set, return true if the idle time condition is met, or false otherwise
      def idle?(now)
        @idle_time.nil? || now >= @last_timestamp + @idle_time
      end

      def leading_edge_debounce(now)
        @mutex.synchronize do
          next if too_soon?(now)
          next unless idle?(now) || max_interval?(now)

          @leading_timestamp = now
          call!
        end
      end

      def start_timer(now)
        @leading_timestamp = now
        @timer = DSL.after(@interval.begin) { @mutex.synchronize { call! } }
      end

      def handle_leading_event(now)
        @leading_timestamp = now
        @initial_wait ||= [@interval.begin, @idle_time].compact.max
        @timer.reschedule(@initial_wait)
      end

      def handle_intermediate_event(now)
        execution_time = @leading_timestamp + @interval.begin

        execution_time = [execution_time, now + @idle_time].max if @idle_time && (@last_timestamp + @idle_time != now)
        if @interval.end
          max_execution_time = @leading_timestamp + @interval.end
          execution_time = max_execution_time if max_execution_time < execution_time
        end

        if execution_time <= now
          @timer.cancel
          call!
        elsif execution_time > @timer.execution_time
          @timer.reschedule(execution_time)
        end
      end

      def trailing_edge_debounce(now)
        @mutex.synchronize do
          next start_timer(now) unless @timer
          next handle_intermediate_event(now) if @timer.active?

          handle_leading_event(now)
        end
      end
    end
  end
end
