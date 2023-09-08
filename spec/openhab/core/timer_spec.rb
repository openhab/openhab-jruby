# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Timer do
  before { Timecop.freeze }

  shared_examples_for "Timer interface" do
    it "works" do
      fired = false
      t = after(0.1.seconds) do |timer|
        fired = true
        expect(timer).to be t
      end
      expect(t).not_to be_a(OpenHAB::RSpec::Mocks::Timer) unless self.class.mock_timers?
      expect(fired).to be false
      time_travel_and_execute_timers(0.5.second)
      expect(fired).to be true
    end

    describe "#reschedule" do
      it "works" do
        start = Time.now
        next_time = start + 15.seconds
        final_time = start + 30.seconds
        t = after(15.seconds) { nil }
        expect(t.execution_time).to eq next_time
        Timecop.freeze(next_time)
        t.reschedule
        expect(t.execution_time).to eq final_time
      end

      it "works from within the execution block" do
        executed = 0
        after(0.1.seconds) do |timer|
          executed += 1
          timer.reschedule if executed == 1
        end

        time_travel_and_execute_timers(0.2.seconds)
        time_travel_and_execute_timers(0.2.seconds)
        expect(executed).to be 2
      end

      it "accepts a new offset (but doesn't memoize it)" do
        start = Time.now
        next_time = start + 15.seconds
        second_time = start + 45.seconds
        final_time = start + 60.seconds
        t = after(15.seconds) { nil }
        expect(t.execution_time).to eq next_time
        Timecop.freeze(next_time)
        t.reschedule(30.seconds)
        expect(t.execution_time).to eq second_time
        Timecop.freeze(second_time)
        t.reschedule
        expect(t.execution_time).to eq final_time
      end
    end

    it "supports integral durations" do
      t = after(5.minutes) { nil }
      expect(t.execution_time).to eq 5.minutes.from_now
    end

    it "supports non-integral durations" do
      t = after(0.5.minutes) { nil }
      expect(t.execution_time).to eq 30.seconds.from_now
    end

    it "supports absolute ZonedDateTime" do
      time = ZonedDateTime.parse("2030-01-01T00:00:00+00:00")
      t = after(time) { nil }
      expect(t.execution_time).to eq time
    end

    it "supports Time" do
      time = Time.parse("2030-01-01T00:00:00+00:00")
      t = after(time) { nil }
      expect(t.execution_time).to eq time
    end

    it "supports Procs" do
      start = Time.now
      next_time = start + 15.seconds
      final_time = start + 30.seconds
      t = after(-> { 15.seconds }) { nil }
      expect(t.execution_time).to eq next_time
      Timecop.freeze(next_time)
      t.reschedule
      expect(t.execution_time).to eq final_time
    end

    describe "#active?" do
      it "is true for a pending timer" do
        t = after(5.minutes) { nil }
        expect(t).to be_active
      end

      it "is false if the timer has been canceled" do
        t = after(5.minutes) { nil }
        t.cancel
        expect(t).not_to be_active
      end

      it "is false if the timer has been executed" do
        t = after(0.1.seconds) { nil }
        time_travel_and_execute_timers(0.5.seconds)
        expect(t).not_to be_active
      end
    end

    describe "#terminated?" do
      it "is false for a pending timer" do
        t = after(5.minutes) { nil }
        expect(t).not_to be_terminated
      end

      it "is true if the timer has been canceled" do
        t = after(5.minutes) { nil }
        t.cancel
        expect(t).to be_terminated
      end

      it "is true if the timer has been executed" do
        t = after(0.1.seconds) { nil }
        time_travel_and_execute_timers(0.5.seconds)
        expect(t).to be_terminated
      end
    end

    it "responds to #running?" do
      t = after(5.minutes) { nil }
      expect(t.respond_to?(:running?)).to be true
    end

    context "with id" do
      def start_timer(duration)
        after(duration, id: "id") { nil }
      end

      it "reuses the same timer if an id is given" do
        timer1 = after(5.seconds, id: "id") { nil }
        expect(timer1.execution_time).to eq 5.seconds.from_now
        after(5.seconds, id: "id") { nil }

        expect(timer1).to be_cancelled
      end

      it "changes its duration to the latest call" do
        start_timer(10.seconds)
        timer = start_timer(5.seconds)
        timer.reschedule
        expect(timer.execution_time).to eq 5.seconds.from_now
      end

      it "can find a timer by id" do
        after(5.seconds, id: "id") { nil }

        expect(timers).to include("id")
      end

      it "removes the timer when canceled" do
        after(5.seconds, id: "id") { nil }

        timers.cancel("id")
        expect(timers).not_to include("id")
      end

      describe "nested inside the execution block of the same id" do
        it "works" do
          executed = []
          2.times do
            after(0.1.seconds, id: :mytimer) do
              executed << 1

              after(0.1.seconds, id: :mytimer) do
                executed << 2
              end
            end

            time_travel_and_execute_timers(0.15.seconds)
          end
          expect(executed).to match_array([1, 1])

          time_travel_and_execute_timers(0.15.seconds)
          expect(executed).to match_array([1, 1, 2])
        end

        it "can be cancelled" do
          result = 0
          after(0.1.seconds, id: :mytimer) do
            result = 1
            after(0.1.seconds, id: :mytimer) do
              result = 2
            end
          end

          time_travel_and_execute_timers(0.15.seconds)
          expect(result).to eq 1
          timers.cancel :mytimer
          expect(timers).not_to include(:mytimer)
          time_travel_and_execute_timers(0.3.seconds)
          expect(result).to eq 1
        end
      end

      it "removes the timer when finished" do
        executed = false
        after(0.1.seconds, id: "id") { executed = true }

        time_travel_and_execute_timers(0.2.seconds)
        expect(executed).to be true
        expect(timers).not_to include("id")
      end

      it "can reschedule a timer by id" do
        timer1 = after(5.seconds, id: "id") { nil }
        timer2 = timers.reschedule("id", 1.second)
        expect(timer2).to be timer1
        expect(timer1.execution_time).to eq 1.second.from_now
      end

      it "can avoid rescheduling timers that already exist" do
        first_executed = second_executed = false
        timer1 = after(5.seconds, id: "id") { first_executed = true }
        timer2 = after(10.seconds, id: "id", reschedule: false) { second_executed = true }
        expect(timer2).to be timer1

        next unless self.class.mock_timers?

        time_travel_and_execute_timers(20.seconds)
        expect(first_executed).to be true
        expect(second_executed).to be false
      end

      it "is reentrant" do
        exec_proofs = []
        (200..500).step(100) do |delay|
          after(delay.milliseconds, id: "id") { exec_proofs << delay }

          expect(timers).to include("id")
        end

        time_travel_and_execute_timers(0.6.seconds)
        expect(exec_proofs).to eq [500]
      end

      it "executes the block from the latest call" do
        result = 0
        after(0.1.seconds, id: "id") { result = 1 }
        after(0.1.seconds, id: "id") { result = 2 }
        after(0.1.seconds, id: "id") { result = 3 }

        expect(result).to eq 0

        time_travel_and_execute_timers(0.2.seconds)
        expect(result).to eq 3
      end

      describe "#reschedule" do
        it "works" do
          executed = 0
          timer = after(100.ms, id: :mytimer) { executed += 1 }
          time_travel_and_execute_timers(70.ms)
          timer.reschedule
          time_travel_and_execute_timers(80.ms)
          expect(executed).to eq 0
          time_travel_and_execute_timers(70.ms)
          expect(executed).to eq 1
        end

        it "works inside the execution block" do
          expect(timers).to receive(:delete).once.and_call_original
          executed = 0
          after(100.ms, id: "id") do |t|
            executed += 1
            t.reschedule if executed == 1
          end

          time_travel_and_execute_timers(150.ms)
          time_travel_and_execute_timers(150.ms)
          expect(executed).to be 2
        end

        it "works on a finished timer" do
          executions = 0
          timer1 = after(100.ms, id: :mytimer) { executions += 1 }

          expect(timers).to include(:mytimer)
          time_travel_and_execute_timers(150.ms)
          expect(executions).to eq 1
          expect(timers).not_to include(:mytimer)

          timer1.reschedule

          expect(timers).to include(:mytimer)
          time_travel_and_execute_timers(150.ms)
          expect(executions).to eq 2
        end

        it "works on a cancelled timer" do
          executions = 0
          timer1 = after(100.ms, id: :mytimer) { executions += 1 }

          expect(timers).to include(:mytimer)

          timer1.cancel

          time_travel_and_execute_timers(150.ms)
          expect(executions).to eq 0
          expect(timers).not_to include(:mytimer)

          timer1.reschedule

          expect(timers).to include(:mytimer)
          time_travel_and_execute_timers(150.ms)
          expect(executions).to eq 1
        end

        it "cancels other timers with the same id" do
          executed = []
          timer1 = after(100.ms, id: :mytimer) { executed << 1 }
          after(100.ms, id: :mytimer) { executed << 2 }

          timer1.reschedule

          time_travel_and_execute_timers(150.ms)
          expect(executed).to match_array([1])
        end
      end

      describe "TimerManager#schedule" do
        it "requires the block to return a valid timer" do
          proper_timer_class = self.class.mock_timers? ? OpenHAB::RSpec::Mocks::Timer : described_class
          real_timer = after(1.second) { nil }
          fake_timer = Struct.new(:id).new(nil)

          expect(timers.schedule("id") { real_timer }).to be_a(proper_timer_class)
          expect { timers.schedule("id") { fake_timer } }.to raise_exception(ArgumentError, /must return a timer/i)
        end
      end
    end
  end

  context "with real timers" do
    # We need to actually test them here
    self.mock_timers = false
    include_examples "Timer interface"

    it "doesn't mock timers" do
      expect(self.class.mock_timers?).to be false
    end
  end

  context "with mock timers" do
    include_examples "Timer interface"

    it "mocks timers" do
      expect(self.class.mock_timers?).to be true
    end

    describe "TimerManager#schedule" do
      it "can _not_ schedule anything if you want" do
        timers.schedule("id") do |timer|
          expect(timer).to be_nil
          nil
        end
      end

      it "can schedule a timer" do
        timer1 = nil
        executed = false
        timer2 = timers.schedule("id") do |_|
          timer1 = after(5.seconds) { executed = true }
        end
        expect(timer2).not_to be_nil
        expect(timer2).to be timer1
        expect(timer1.id).to eql "id"
        expect(executed).to be false
        expect(timers).to include("id")

        timer3 = timers.schedule("id") do |timer|
          expect(timer).to be timer1
          timer
        end
        expect(timer3).to be timer1

        time_travel_and_execute_timers(10.seconds)
        expect(executed).to be true
      end

      it "can reschedule an existing timer" do
        executed = false
        timers.schedule("id") do |_|
          after(5.seconds) { executed = true }
        end

        timers.schedule("id") do |timer|
          timer.reschedule(10.seconds)
        end

        time_travel_and_execute_timers(7.seconds)
        expect(executed).to be false
        time_travel_and_execute_timers(7.seconds)
        expect(executed).to be true
      end

      it "cancels a timer if you return nil from the block" do
        executed = false
        timers.schedule("id") do |_|
          after(5.seconds) { executed = true }
        end

        timers.schedule("id") do |_|
          nil
        end

        expect(timers).not_to include("id")
        time_travel_and_execute_timers(7.seconds)
        expect(executed).to be false
      end

      it "removes a canceled timer" do
        executed = false
        timers.schedule("id") do |_|
          after(5.seconds) { executed = true }
        end

        timers.schedule("id") do |timer|
          timer.tap(&:cancel)
        end

        expect(timers).not_to include("id")
        time_travel_and_execute_timers(7.seconds)
        expect(executed).to be false
      end
    end
  end
end
