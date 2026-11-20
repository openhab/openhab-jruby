# frozen_string_literal: true

module OpenHAB
  module RSpec
    module Mocks
      # Schedule rule time triggers against the same clock as mocked Ruby timers.
      class CronScheduler
        include org.openhab.core.scheduler.CronScheduler

        class << self
          attr_reader :schedules

          def execute_timers(now)
            schedules.to_a.each { |schedule| schedule.execute(now) }
          end
        end
        @schedules = java.util.concurrent.ConcurrentHashMap.new_key_set

        class Schedule < java.util.concurrent.CompletableFuture
          include org.openhab.core.scheduler.ScheduledCompletableFuture

          def initialize(runnable, expression, config = nil)
            super()
            @runnable = runnable
            @config = config
            @adjuster = org.openhab.core.scheduler.CronAdjuster.new(expression)
            reschedule(java.time.ZonedDateTime.now)
          end

          def get_promise # rubocop:disable Naming/AccessorMethodName -- Java interface
            self
          end

          def get_scheduled_time # rubocop:disable Naming/AccessorMethodName -- Java interface
            @scheduled_time
          end

          def get_delay(unit)
            nanos = java.time.Duration.between(java.time.ZonedDateTime.now, @scheduled_time).to_nanos
            unit.convert(nanos, java.util.concurrent.TimeUnit::NANOSECONDS)
          end

          def compare_to(other)
            get_delay(java.util.concurrent.TimeUnit::NANOSECONDS) <=>
              other.get_delay(java.util.concurrent.TimeUnit::NANOSECONDS)
          end

          def cancel(interrupt)
            CronScheduler.schedules.remove(self)
            super
          end

          def execute(now)
            return if done? || @scheduled_time > now

            begin
              @config ? @runnable.run(@config) : @runnable.run
            ensure
              reschedule(now) unless done?
            end
          end

          private

          def reschedule(now)
            now = now.with_zone_same_instant(java.time.ZoneId.system_default)

            if @adjuster.is_done(now)
              complete(nil)
              CronScheduler.schedules.remove(self)
              return
            end

            @scheduled_time = @adjuster.adjust_into(now.with_nano(0))
            if @adjuster.is_done(@scheduled_time)
              complete(nil)
              CronScheduler.schedules.remove(self)
            else
              CronScheduler.schedules.add(self)
            end
          rescue java.time.DateTimeException
            complete(nil)
            CronScheduler.schedules.remove(self)
          end
        end

        def initialize(scheduler)
          @scheduler = scheduler
        end

        def schedule(runnable, *args)
          return @scheduler.schedule(runnable, *args) if defined?(Timer) && !Timer.mock_timers?

          Schedule.new(runnable, args.last, (args.size == 2) ? args.first : nil)
        end
      end
    end
  end
end
