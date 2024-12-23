# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::DateTimeType do
  let(:date1) { DateTimeType.new("1970-01-01T00:00:00+00:00") }
  let(:date2) { DateTimeType.new("2021-01-31T08:00:00+00:00") }
  let(:date3) { DateTimeType.new("2021-01-31T14:00:00+06:00") }

  describe "#initialize" do
    it "initializes to `now` if no argument is given" do
      expect(DateTimeType.new.to_zoned_date_time.to_epoch_second).to be_within(1).of(ZonedDateTime.now.to_epoch_second)
    end
  end

  describe "math operations" do
    let(:date1) { DateTimeType.new("1970-01-31T08:00:00+0200") }

    specify { expect(date1 + 600).to eq Time.parse("1970-01-31T08:10:00.000+0200") }
    specify { expect(date1 - 600).to eq Time.parse("1970-01-31T07:50:00.000+0200") }
    specify { expect(date1 + 20.minutes).to eq Time.parse("1970-01-31T08:20:00.000+0200") }
    specify { expect(date1 - 20.minutes).to eq Time.parse("1970-01-31T07:40:00.000+0200") }
  end

  describe "Ruby time methods" do
    specify { expect(date2).to be_sunday }
    specify { expect(date2).not_to be_monday }
    specify { expect(date2.wday).to be 0 }
    specify { expect(date2).to be_utc }
    specify { expect(date2.month).to be 1 }

    if OpenHAB::Core.version < OpenHAB::Core::V4_3
      specify { expect(date2.zone).to eql "Z" }
    else
      specify { expect(date2.zone).to eql "Etc/UTC" }
    end
  end

  it "considers same time but different zone to be equal" do
    expect(date2).to eq date3
  end

  describe "calculating time differences" do
    let(:date1) { DateTimeType.new("2021-01-31T09:00:00+00:00") }

    specify { expect((date1 - Time.parse("2021-01-31T07:00:00+00:00")).to_i).to be 7200 }
    specify { expect((date1 - Time.utc(2021, 1, 31, 7)).to_i).to be 7200 }
    specify { expect((date1 - date2).to_i).to be 3600 }
  end

  it "works with LocalTime ranges" do
    expect(
      case date3
      when between("00:00"..."08:00") then 1
      when between("08:00"..."16:00") then 2
      when between("16:00".."23:59") then 3
      end
    ).to be 2
  end

  it "can create between ranges" do
    expect(date1...date2).to cover(Time.parse("2021-01-31T05:00:00+00:00"))
  end

  describe "comparisons" do
    let(:date_one) { DateTimeType.new("2021-01-01T00:00:00+00:00") }
    let(:date_two) { DateTimeType.new("2021-02-01T12:00:00+00:00") }

    specify { expect(date_one).to be < date_two }
    specify { expect(date_one).to be <= Date.parse("2021-02-09") }
    specify { expect(date_one).not_to be > Time.now }
    specify { expect(date_one).to eq Time.parse("2021-01-01T00:00:00+00:00") }
    specify { expect(date_one != Time.parse("2021-01-01T00:00:00+00:00")).to be false }

    specify { expect(date_two).not_to be < date_one }
    specify { expect(Date.parse("2021-02-09")).to be >= date_one }
    specify { expect(Time.now).to be > date_one }
    specify { expect(Time.parse("2021-01-01T00:00:00+00:00")).to eq date_one }
    specify { expect(Time.parse("2021-01-01T00:00:00+01:00") != date_one).to be true }
  end

  describe "#parse" do
    it "use local date and timezone for time only strings without a timezone" do
      expect(DateTimeType.parse("3:30pm")).to eq LocalTime.parse("3:30pm").to_zoned_date_time
      expect(DateTimeType.parse("03:30:00")).to eq LocalTime.parse("3:30").to_zoned_date_time
    end

    it "parses time only strings with a timezone" do
      expect(DateTimeType.parse("3:30-1000")).to eq Time.parse("3:30-1000").to_zoned_date_time
    end
  end

  describe "#to_instant" do
    it "works" do
      expect(date3.to_instant).to eq Instant.parse("2021-01-31T08:00:00Z")
    end
  end
end
