# frozen_string_literal: true

RSpec.describe "timers" do
  it "only executes after time has moved, and you explicitly execute them" do
    executed = false
    after(5.minutes) { executed = true }

    expect(executed).to be false
    Timecop.travel(10.minutes)
    expect(executed).to be false
    execute_timers
    expect(executed).to be true
  end

  it "deregisters a timer whose block raises, so cancel_all can finish" do
    after(1.second, id: :raiser) { raise "boom" }

    Timecop.travel(2.seconds)
    expect { execute_timers }.to raise_error("boom")

    expect(OpenHAB::DSL.timers).not_to include(:raiser)
    Timeout.timeout(5) { OpenHAB::DSL.timers.cancel_all }
  end

  it "keeps a timer registered when its block reschedules it and then raises" do
    after(1.second, id: :rescheduler) do |timer|
      timer.reschedule(1.second)
      raise "boom"
    end

    Timecop.travel(2.seconds)
    expect { execute_timers }.to raise_error("boom")

    expect(OpenHAB::DSL.timers).to include(:rescheduler)
    Timeout.timeout(5) { OpenHAB::DSL.timers.cancel_all }
    expect(OpenHAB::DSL.timers).not_to include(:rescheduler)
  end

  it "lets cancel_all finish even if a terminated timer is still registered" do
    timer = after(1.second, id: :lingering) { nil }
    Timecop.travel(2.seconds)
    execute_timers
    OpenHAB::DSL::TimerManager.instance.add(timer)
    expect(timer).to be_terminated

    Timeout.timeout(5) { OpenHAB::DSL.timers.cancel_all }
  end
end
