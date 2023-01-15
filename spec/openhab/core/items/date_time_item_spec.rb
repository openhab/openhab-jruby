# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::DateTimeItem do
  before do
    items.build do
      date_time_item "DateOne", state: "1970-01-01T00:00:00+00:00"
    end
  end

  it "accepts ZonedDateTime" do
    DateOne << ZonedDateTime.of(1999, 12, 31, 0, 0, 0, 0, ZoneId.of("UTC"))
    expect(DateOne.state).to eq Time.parse("1999-12-31T00:00:00.000+0000")
  end

  it "can be updated by Ruby Time objects" do
    DateOne << Time.at(60 * 60 * 24).utc
    expect(DateOne.state).to eq Time.parse("1970-01-02T00:00:00.000+0000")
  end

  it "can be updated by a string that looks like a time" do
    DateOne.update("3:30pm")
    expect(DateOne.state).to eq LocalTime.parse("3:30pm").to_zoned_date_time
  end
end
