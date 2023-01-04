# frozen_string_literal: true

RSpec.describe Timecop do
  it "returns the frozen value for all Java classes" do
    now = ZonedDateTime.parse("1991-02-03T04:05:06.000000-07:00")
    described_class.freeze(now)
    expect(ZonedDateTime.now).to eq now
    expect(MonthDay.now).to eq MonthDay.of(2, 3)
    expect(LocalDate.now).to eq LocalDate.of(1991, 2, 3)
    expect(LocalTime.now).to eq LocalTime.of(4, 5, 6, 0)
  end
end
