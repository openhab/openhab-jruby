# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Debouncer do
  before { Timecop.freeze(2000, 1, 1) }

  it "works" do
    called = false
    debouncer = described_class.new(for: 100.ms)
    debouncer.call { called = true }
    expect(called).to be false
    time_travel_and_execute_timers(101.ms)
    expect(called).to be true
  end

  describe "Leading Edge Triggers" do
    it "works" do
      counter = 0
      debouncer = described_class.new(for: 100.ms, leading: true)

      debouncer.call { counter += 1 } # this first call should execute right away
      expect(counter).to eq 1

      time_travel_and_execute_timers(50.ms)
      expect(counter).to eq 1

      time_travel_and_execute_timers(200.ms)
      expect(counter).to eq 1

      debouncer.call { counter += 1 } # a new cycle first call should execute right away
      expect(counter).to eq 2
    end

    it "ignores all the calls after the first one within the debounce period" do
      captured = []
      debouncer = described_class.new(for: 100.ms, leading: true)

      debouncer.call { captured << 1 } # the first call should be executed right away
      expect(captured).to eq [1]

      5.times do
        debouncer.call { captured << 2 } # and this should be ignored
      end
      expect(captured).to eq [1]

      time_travel_and_execute_timers(80.ms)
      expect(captured).to eq [1]

      time_travel_and_execute_timers(100.ms)
      expect(captured).to eq [1]

      debouncer.call { captured << 3 } # this is a new cycle
      expect(captured).to eq [1, 3]

      debouncer.call { captured << 4 } # this will be ignored

      time_travel_and_execute_timers(40.ms)
      expect(captured).to eq [1, 3]

      debouncer.call { captured << 5 } # this will be ignored too
      expect(captured).to eq [1, 3]

      time_travel_and_execute_timers(105.ms) # new cycle, but no new calls
      expect(captured).to eq [1, 3]
    end

    it "works when idle_time > interval" do
      counter = 0
      debouncer = described_class.new(for: 100.ms, leading: true, idle_time: 500.ms)
      debouncer.call { counter += 1 }
      expect(counter).to eq 1 # leading trigger: the first one gets in

      time_travel_and_execute_timers(90.ms)
      5.times do
        debouncer.call
        time_travel_and_execute_timers(100.ms) # interval between calls < idle_time
      end

      expect(counter).to eq 1 # no executions should happen

      time_travel_and_execute_timers(410.ms) # 100ms + 410ms > idle_time
      debouncer.call # This should satisfy idle_time and count as a new leading edge trigger
      expect(counter).to eq 2
    end

    it "works when idle_time < interval" do
      counter = 0
      debouncer = described_class.new(for: 500.ms, leading: true, idle_time: 100.ms)
      debouncer.call { counter += 1 }
      expect(counter).to eq 1 # leading trigger: the first one gets in

      time_travel_and_execute_timers(490.ms) # advance near the end of the interval
      5.times do
        debouncer.call
        time_travel_and_execute_timers(95.ms) # interval between calls < idle_time
      end

      expect(counter).to eq 1 # no executions should happen

      time_travel_and_execute_timers(410.ms) # 95 + 410ms > period
      debouncer.call # This should satisfy idle_time and period to count as a new leading edge trigger
      expect(counter).to eq 2
    end

    it "supports max interval" do
      counter = 0
      debouncer = described_class.new(for: (100.ms)..(600.ms), leading: true, idle_time: 500.ms)
      debouncer.call { counter += 1 }
      expect(counter).to eq 1 # leading trigger: the first one gets in

      time_travel_and_execute_timers(90.ms)
      5.times do
        debouncer.call
        time_travel_and_execute_timers(100.ms) # interval between calls < idle_time
      end

      # total time since leading edge: 590ms
      expect(counter).to eq 1 # no executions should happen
      debouncer.call
      expect(counter).to eq 1 # no executions should happen
      time_travel_and_execute_timers(20.ms) # total time since leading edge: 610ms > max_interval

      debouncer.call # this call is allowed to execute as the new leading edge
      expect(counter).to eq 2 # no executions should happen
    end

    it "executes at the correct time for periodic calls < interval" do
      interval = 5
      periods = 10

      # fire up a bunch of calls that occur more often than the interval
      # but make sure the edges are sync-ed to the interval, so we can
      # get executions that are perfectly timed to the interval
      timestamps = []

      start_time = Timecop.freeze(Time.at(0))

      debouncer = described_class.new(for: interval.seconds, leading: true)

      periods.times do
        debouncer.call { timestamps << Time.now } # this is perfectly timed to the leading edge
        interval.times do
          Timecop.freeze(1) # advance 1 second
          debouncer.call # these should all be debounced
        end
      end
      expect(timestamps.size).to eq(periods + 1)

      # now let's verify the execution intervals
      baseline = timestamps.first
      expect(baseline).to eq start_time
      timestamps.each do |timestamp|
        expect(timestamp).to eq baseline
        baseline += interval
      end
    end

    it "executes at the correct time for calls > interval" do
      interval = 5

      timestamps = []
      reference = []
      debouncer = described_class.new(for: interval.seconds, leading: true)

      10.times do
        delta = interval + rand(1...interval) # advance past the normal interval
        reference << Timecop.freeze(delta)
        debouncer.call { timestamps << Time.now }
      end

      expect(timestamps.size).to eq 10 # all calls should've been executed
      expect(timestamps).to eq reference
    end
  end

  describe "Trailing Edge Triggers" do
    it "works" do
      counter = 0
      debouncer = described_class.new(for: 100.ms)
      time_travel_and_execute_timers(100.ms) # no timers should've started

      debouncer.call { counter += 1 } # this first call should kick off a timer
      expect(counter).to eq 0 # it shouldn't have executed right away

      time_travel_and_execute_timers(95.ms)
      expect(counter).to eq 0 # still below the debounce period

      time_travel_and_execute_timers(6.ms)
      expect(counter).to eq 1 # it should have executed here

      time_travel_and_execute_timers(200.ms)
      expect(counter).to eq 1 # there were no outstanding calls, so it shouldn't execute again

      debouncer.call { counter += 1 } # first call after the last execution, start a new period

      time_travel_and_execute_timers(99.ms)
      expect(counter).to eq 1 # it shouldn't have executed yet

      time_travel_and_execute_timers(2.ms) # go past the debounce period
      expect(counter).to eq 2 # it should have executed now
    end

    it "ignores all the calls except the last one within the debounce period" do
      captured = []
      debouncer = described_class.new(for: 100.ms)

      debouncer.call { captured << 1 } # this first call starts a new period
      debouncer.call { captured << 2 }
      debouncer.call { captured << 3 }

      time_travel_and_execute_timers(105.ms)
      expect(captured).to eq [3] # it should only execute the last call

      debouncer.call { captured << 4 } # start a new period

      time_travel_and_execute_timers(50.ms)
      debouncer.call { captured << 5 }

      time_travel_and_execute_timers(50.ms)
      expect(captured).to eq [3, 5] # it should only execute the last call
    end

    it "works when idle_time > interval" do
      counter = 0
      debouncer = described_class.new(for: 100.ms, idle_time: 500.ms)
      debouncer.call { counter += 1 }
      expect(counter).to eq 0 # trailing edge trigger, nothing should execute yet

      time_travel_and_execute_timers(110.ms)
      # The first call should execute after the initial period.
      # because there were no triggers before that to violate idle_time
      expect(counter).to eq 1

      4.times do
        debouncer.call
        time_travel_and_execute_timers(110.ms) # interval between calls < idle_time
      end
      expect(counter).to eq 1 # no executions should happen even though interval between calls > 100ms

      time_travel_and_execute_timers(400.ms) # 510ms > idle_time
      expect(counter).to eq 2
    end

    it "works when idle_time < interval" do
      counter = 0
      debouncer = described_class.new(for: 500.ms, idle_time: 100.ms)

      debouncer.call { counter += 1 } # the initial trigger
      expect(counter).to eq 0 # trailing edge trigger, nothing should execute yet

      time_travel_and_execute_timers(450.ms)
      expect(counter).to eq 0 # it should wait for the minimum period

      debouncer.call # shouldn't trigger anything
      expect(counter).to eq 0 # it should wait for the minimum period

      time_travel_and_execute_timers(90.ms) # go past the period since initial trigger
      expect(counter).to eq 0 # it shouldn't trigger here because 90ms < idle_time

      time_travel_and_execute_timers(20.ms) # now to past the idle_time
      expect(counter).to eq 1 # it should have triggered by now because it's past the minimum idle time
    end

    it "supports interval range" do
      counter = 0
      debouncer = described_class.new(for: (100.ms)..(600.ms), idle_time: 500.ms)
      debouncer.call { counter += 1 }
      expect(counter).to eq 0 # trailing edge trigger, nothing should execute yet

      time_travel_and_execute_timers(90.ms) # go near the end of the period
      5.times do
        debouncer.call
        time_travel_and_execute_timers(100.ms) # interval between calls < idle_time
      end

      # total time now: 590ms < max_interval
      expect(counter).to eq 0 # no executions should happen

      debouncer.call # another call that trips idle_time
      expect(counter).to eq 0 # still, no executions should happen

      time_travel_and_execute_timers(15.ms) # 605ms > max_interval
      expect(counter).to eq 1 # An execution should have now happened to satisfy max_interval
    end

    it "executes at the correct time for periodic calls < interval" do
      interval = 5
      periods = 10

      debouncer = described_class.new(for: interval.seconds)

      start_time = Timecop.freeze(Time.at(0))

      timestamps = []
      periods.times do
        debouncer.call { timestamps << Time.now } # The leading edge starts the timer
        interval.times do
          time_travel_and_execute_timers(1) # advance 1 second
          debouncer.call
        end
      end
      expect(timestamps.size).to eq periods

      baseline = timestamps.first
      expect(baseline).to eq start_time + interval
      timestamps.each do |timestamp|
        expect(timestamp).to eq baseline
        baseline += interval
      end
    end

    it "executes at the correct time for periodic calls == interval" do
      interval = 5
      periods = 10

      timestamps = []
      debouncer = described_class.new(for: interval.seconds)

      start_time = Timecop.freeze(Time.at(0))

      periods.times do
        debouncer.call { timestamps << Time.now } # The leading edge starts the timer
        interval.times do
          time_travel_and_execute_timers(1) # second by second. Timers can't execute in the past
        end
      end
      expect(timestamps.size).to eq periods

      baseline = timestamps.first
      expect(baseline).to eq start_time + interval
      timestamps.each do |timestamp|
        expect(timestamp).to eq baseline
        baseline += interval
      end
    end

    it "executes at the correct time for calls > interval" do
      interval = 5
      periods = 10

      timestamps = []
      reference = []
      debouncer = described_class.new(for: interval.seconds)

      Timecop.freeze(Time.at(0))
      periods.times do
        delta = interval + rand(1...interval) # advance past the normal interval
        debouncer.call { timestamps << Time.now } # this starts the timer
        reference << (Time.now + interval) # which should execute at now + interval

        # We have to time travel 1 second a time to execute the timer at the right time
        delta.times { time_travel_and_execute_timers(1) }
      end

      expect(timestamps.size).to eq periods # all calls should've been executed
      expect(timestamps).to eq reference
    end
  end

  describe "#call" do
    it "passes through the block call without debouncing when given for: nil argument" do
      counter = 0
      debouncer = described_class.new(for: nil)
      20.times { debouncer.call { counter += 1 } }
      expect(counter).to eq 20
    end

    it "calls the previous block when no block is provided" do
      counter = 0
      debouncer = described_class.new(for: 100.ms, leading: true)
      debouncer.call { counter += 1 }
      time_travel_and_execute_timers(110.ms) # a new period starts
      debouncer.call # This should trigger a leading edge execution
      expect(counter).to eq 2
    end
  end

  describe "#reset" do
    it "cancels outstanding trailing events" do
      captured = []
      debouncer = described_class.new(for: 100.ms)
      debouncer.call { captured << (captured.size + 1) }
      debouncer.reset
      time_travel_and_execute_timers(120.ms)
      expect(captured).to be_empty
      debouncer.call
    end

    it "starts a new debounce cycle" do
      captured = []
      debouncer = described_class.new(for: 100.ms, leading: true)
      debouncer.call { captured << (captured.size + 1) }
      3.times { debouncer.call } # These should be ignored
      debouncer.reset # starts a new cycle
      debouncer.call # This becomes the new leading event that gets executed
      expect(captured).to eq [1, 2]
    end

    it "resets the period of a trailing edge debouncer" do
      counter = 0
      debouncer = described_class.new(for: 100.ms)
      debouncer.call { counter += 1 }
      time_travel_and_execute_timers(90.ms)

      debouncer.reset

      time_travel_and_execute_timers(20.ms) # without the reset, this would've executed the block
      expect(counter).to eq 0 # but it didn't because it was reset 20ms ago

      debouncer.call # this is the first call in the new cycle
      expect(counter).to eq 0 # and it shouldn't have executed

      time_travel_and_execute_timers(75.ms) # still below the debounce period
      expect(counter).to eq 0 # only 95ms so far, so keep waiting

      debouncer.call # so this last call should be delayed until the end of the period
      expect(counter).to eq 0 # and it shouldn't have executed

      time_travel_and_execute_timers(30.ms) # go past the debounce period
      expect(counter).to eq 1 # so it should have executed the most recent call above
    end
  end

  describe "#flush" do
    it "performs outstanding trailing edge executions" do
      called = false
      debouncer = described_class.new(for: 100.ms)
      debouncer.call { called = true }
      debouncer.flush
      time_travel_and_execute_timers(0.ms)
      expect(called).to be true
    end
  end
end
