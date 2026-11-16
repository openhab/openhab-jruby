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
end
