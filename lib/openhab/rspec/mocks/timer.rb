# frozen_string_literal: true

require "timecop"

module OpenHAB
  module RSpec
    module Mocks
      class Timer < Core::Timer
        # @!visibility private
        module MockedZonedDateTime
          def now
            mocked_time_stack_item = Timecop.top_stack_item
            return super unless mocked_time_stack_item

            mocked_time_stack_item.time.to_zoned_date_time
          end
        end
        ZonedDateTime.singleton_class.prepend(MockedZonedDateTime)

        # @!visibility private
        module MockedLocalDate
          def now
            mocked_time_stack_item = Timecop.top_stack_item
            return super unless mocked_time_stack_item

            mocked_time_stack_item.time.to_zoned_date_time.to_local_date
          end
        end
        LocalDate.singleton_class.prepend(MockedLocalDate)

        # @!visibility private
        module MockedLocalTime
          def now
            mocked_time_stack_item = Timecop.top_stack_item
            return super unless mocked_time_stack_item

            mocked_time_stack_item.time.to_zoned_date_time.to_local_time
          end
        end
        LocalTime.singleton_class.prepend(MockedLocalTime)

        # @!visibility private
        module MockedMonthDay
          def now
            mocked_time_stack_item = Timecop.top_stack_item
            return super unless mocked_time_stack_item

            mocked_time_stack_item.time.to_zoned_date_time.to_month_day
          end
        end
        MonthDay.singleton_class.prepend(MockedMonthDay)

        # extend Timecop to support Java time classes
        # @!visibility private
        module TimeCopStackItem
          def parse_time(*args)
            if args.length == 1
              arg = args.first
              if arg.is_a?(Time) ||
                 (defined?(DateTime) && arg.is_a?(DateTime)) ||
                 (defined?(Date) && arg.is_a?(Date))
                return super
              elsif arg.respond_to?(:to_zoned_date_time)
                return arg.to_zoned_date_time.to_time
              elsif arg.is_a?(java.time.temporal.TemporalAmount)
                return (ZonedDateTime.now + arg).to_time
              end
            end

            super
          end
        end
        Timecop::TimeStackItem.prepend(TimeCopStackItem)

        attr_reader :execution_time, :id, :block

        def initialize(time, id:, thread_locals:, block:) # rubocop:disable Lint/MissingSuper
          @time = time
          @id = id
          @block = block
          @thread_locals = thread_locals
          reschedule(time)
        end

        def reschedule(time = nil)
          Thread.current[:openhab_rescheduled_timer] = true if Thread.current[:openhab_rescheduled_timer] == self
          @execution_time = new_execution_time(time || @time)
          @executed = false

          DSL::TimerManager.instance.add(self)

          self
        end

        def execute
          raise "Timer already cancelled" if cancelled?
          raise "Timer already executed" if terminated?

          @executed = true
          super
        end

        def cancel
          return false if terminated? || cancelled?

          DSL::TimerManager.instance.delete(self)
          cancel!
          true
        end

        def cancel!
          @execution_time = nil
          true
        end

        def cancelled?
          @execution_time.nil?
        end

        def terminated?
          @executed || cancelled?
        end

        def running?
          false
        end

        def active?
          !terminated?
        end
      end
    end
  end
end
