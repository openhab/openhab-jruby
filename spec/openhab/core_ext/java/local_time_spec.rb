# frozen_string_literal: true

RSpec.describe java.time.LocalTime do
  let(:time) { described_class.parse("03:22:01") }

  describe ".parse" do
    specify { expect(described_class.parse("1").to_s).to eql "01:00" }
    specify { expect(described_class.parse("02").to_s).to eql "02:00" }
    specify { expect(described_class.parse("1pm").to_s).to eql "13:00" }
    specify { expect(described_class.parse("12:30").to_s).to eql "12:30" }
    specify { expect(described_class.parse("12 am").to_s).to eql "00:00" }
    specify { expect(described_class.parse("7:00 AM").to_s).to eql "07:00" }
    specify { expect(described_class.parse("7:00 pm").to_s).to eql "19:00" }
    specify { expect(described_class.parse("7:30:20am").to_s).to eql "07:30:20" }
    specify { expect { described_class.parse("12  am") }.to raise_error ArgumentError }
    specify { expect { described_class.parse("17:00pm") }.to raise_error ArgumentError }
    specify { expect { described_class.parse("17:00am") }.to raise_error ArgumentError }
    specify { expect(described_class.parse("7:30:20.12").to_s).to eql "07:30:20.120" }
    specify { expect(described_class.parse("7:30:20.12345").to_s).to eql "07:30:20.123450" }

    it "can accept a formatter" do
      formatter = java.time.format.DateTimeFormatter::ISO_OFFSET_TIME
      expect(described_class.parse("10:15:30+00:00", formatter).to_s).to eql "10:15:30"
    end
  end

  describe "#+" do
    it "works with a Period" do
      expect(time + 1.year).to be time
      expect(time + 1.day).to be time
    end

    it "works with a Duration" do
      expect(time + 2.hours).to eql LocalTime.parse("05:22:01")
    end

    it "works with integers" do
      expect(time + 1).to eql LocalTime.parse("03:22:02")
    end
  end

  describe "#-" do
    it "works with a Period" do
      expect(time - 1.year).to be time
      expect(time - 1.day).to be time
    end

    it "works with a Duration" do
      expect(time - 2.hours).to eql LocalTime.parse("01:22:01")
    end

    it "works with integers" do
      expect(time - 1).to eql LocalTime.parse("03:22:00")
    end
  end

  describe "#to_zoned_date_time" do
    it "takes on the date of the contextual time" do
      context = ZonedDateTime.parse("1990-05-04T03:02:01+03:00")
      expect(time.to_zoned_date_time(context)).to eql ZonedDateTime.parse("1990-05-04T03:22:01+03:00")
      expect(time.to_zoned_date_time.month_value).to be Time.now.month
    end
  end

  describe "#succ" do
    it "works" do
      expect(time.succ).to eql LocalTime.parse("03:22:02")
    end

    it "rolls across midnight" do
      expect(LocalTime.parse("23:59:59").succ).to eql LocalTime.parse("00:00:00")
    end
  end

  describe "#<=>" do
    context "with a LocalTime" do
      let(:other) { LocalTime.parse("03:22:01") }

      specify { expect(time).to eq other }
      specify { expect(time).to eql other }
      specify { expect(time).to be <= other }
      specify { expect(time).not_to be <= (other - 1.second) }
      specify { expect(time).to be >= other }
      specify { expect(time).not_to be >= (other + 1.second) }
      specify { expect(time).not_to be < other }
      specify { expect(time).to be < (other + 1.second) }
      specify { expect(time).not_to be > other }
      specify { expect(time).to be > (other - 1.second) }
    end

    context "with a ZonedDateTime" do
      let(:other) { time.to_zoned_date_time }

      specify { expect(time).to eq other }
      specify { expect(time).not_to eql other }
      specify { expect(time).to be <= other }
      specify { expect(time).not_to be <= (other - 1.second) }
      specify { expect(time).to be >= other }
      specify { expect(time).not_to be >= (other + 1.second) }
      specify { expect(time).not_to be < other }
      specify { expect(time).to be < (other + 1.second) }
      specify { expect(time).not_to be > other }
      specify { expect(time).to be > (other - 1.second) }
    end

    context "with a Time" do
      let(:other) { time.to_zoned_date_time.to_time }

      specify { expect(time).to eq other }
      specify { expect(time).not_to eql other }
      specify { expect(time).to be <= other }
      specify { expect(time).not_to be <= (other - 1) }
      specify { expect(time).to be >= other }
      specify { expect(time).not_to be >= (other + 1) }
      specify { expect(time).not_to be < other }
      specify { expect(time).to be < (other + 1) }
      specify { expect(time).not_to be > other }
      specify { expect(time).to be > (other - 1) }
    end
  end

  describe "in a range" do
    let(:minus5) { (Time.now - 5.minutes).to_local_time }
    let(:plus5) { (Time.now + 5.minutes).to_local_time }
    let(:plus10) { (Time.now + 10.minutes).to_local_time }

    specify { expect((minus5..plus5).cover?(Time.now)).to be true }
    specify { expect((plus5..plus10).cover?(Time.now)).to be false }
    specify { expect((minus5..plus5).cover?(LocalTime.now)).to be true }
    specify { expect((plus5..plus10).cover?(LocalTime.now)).to be false }

    it "can be used in a case statement" do
      r = case Time.now
          when minus5..plus5 then 1
          when plus5..plus10 then 2
          end
      expect(r).to be 1
    end
  end

  describe "#between?" do
    let(:minus5) { (time - 5.minutes).to_local_time }
    let(:plus5) { (time + 5.minutes).to_local_time }

    it "works with min, max" do
      expect(time.between?("1:00", "4:00")).to be true
      expect(time.between?(minus5, plus5)).to be true
      expect(time.between?(time, plus5)).to be true
      expect(time.between?(minus5, time)).to be true
      expect(time.between?(minus5, minus5)).to be false
    end

    it "works with range" do
      expect(time.between?("1:00".."4:00")).to be true
      expect(time.between?(minus5..plus5)).to be true
      expect(time.between?(minus5..time)).to be true
      expect(time.between?(minus5...time)).to be false
    end
  end
end
