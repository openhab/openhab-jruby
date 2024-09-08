# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::DateTimeItem do
  subject(:item) do
    items.build do
      date_time_item "DateOne", state: "1970-01-01T00:00:00+00:00"
    end
  end

  it "is a date_time" do
    expect(item).to be_a_date_time_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  it "accepts ZonedDateTime" do
    item << ZonedDateTime.of(1999, 12, 31, 0, 0, 0, 0, ZoneId.of("UTC"))
    expect(item.state).to eq Time.parse("1999-12-31T00:00:00.000+0000")
  end

  it "can be updated by Ruby Time objects" do
    item << Time.at(60 * 60 * 24).utc
    expect(item.state).to eq Time.parse("1970-01-02T00:00:00.000+0000")
  end

  it "can be updated by a string that looks like a time" do
    item.update("3:30pm")
    expect(item.state).to eq LocalTime.parse("3:30pm").to_zoned_date_time
  end

  it "can be updated by a string that looks like a date" do
    item.update("2021-01-01")
    expect(item.state).to eq LocalDate.parse("2021-01-01").to_zoned_date_time
  end

  it "can be updated by a string that looks like a date and time" do
    item.update("2021-01-01 15:40Z")
    expect(item.state).to eq ZonedDateTime.parse("2021-01-01T15:40Z")
  end
end
