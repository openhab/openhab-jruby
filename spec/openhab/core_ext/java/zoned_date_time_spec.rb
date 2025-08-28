# frozen_string_literal: true

RSpec.describe java.time.ZonedDateTime do
  describe "#to_i" do
    it "returns epoch seconds" do
      now = Time.now
      expect(now.to_zoned_date_time.to_i).to be now.to_i
    end
  end

  describe "#to_f" do
    it "returns epoch seconds as float" do
      now = Time.now
      expect(now.to_zoned_date_time.to_f).to be_within(1 / 1_000_000.0).of(now.to_f)
    end
  end

  describe "#+" do
    it "works with duration" do
      now = described_class.now
      expect((now + 5.seconds).to_i).to be(now.to_i + 5)
      expect((now + 2.minutes).to_i).to be(now.to_i + 120)
    end

    it "works with integers" do
      now = described_class.now
      expect((now + 5).to_i).to be(now.to_i + 5)
    end

    it "works with Time QuantityType" do
      now = described_class.now
      expect((now + QuantityType.new("5 s")).to_i).to be(now.to_i + 5)
    end
  end

  describe "#-" do
    it "works with duration" do
      now = described_class.now
      expect((now - 5.seconds).to_i).to be(now.to_i - 5)
      expect((now - 2.minutes).to_i).to be(now.to_i - 120)
    end

    it "works with integers" do
      now = described_class.now
      expect((now - 5).to_i).to be(now.to_i - 5)
    end

    it "works with Time QuantityType" do
      now = described_class.now
      expect(now - QuantityType.new("5 s")).to be_a described_class
      expect((now - QuantityType.new("5 s")).to_i).to be(now.to_i - 5)
    end

    it "returns a duration for another ZonedDateTime instance" do
      now = described_class.now
      future = now + 5.seconds
      expect(future - now).to eql 5.seconds
    end

    it "returns a duration for a Time instance" do
      now = described_class.now
      future = (now + 5.seconds)
      expect(future - now.to_time).to eql 5.seconds
    end
  end

  describe "#to_date" do
    it "works" do
      expect(described_class.parse("2022-11-09T02:09:05+00:00").to_date).to eql Date.new(2022, 11, 9)
    end
  end

  describe "#to_local_date" do
    it "works" do
      expect(described_class.parse("2022-11-09T02:09:05+00:00").to_local_date)
        .to eql java.time.LocalDate.parse("2022-11-09")
    end
  end

  describe "#to_local_time" do
    it "works" do
      expect(described_class.parse("2022-11-09T02:09:05+00:00").to_local_time)
        .to eql LocalTime.parse("02:09:05")
    end
  end

  describe "#to_month" do
    it "works" do
      expect(described_class.parse("2022-11-09T00:00:00+00:00").to_month).to eql java.time.Month::NOVEMBER
    end
  end

  describe "#to_month_day" do
    it "works" do
      expect(described_class.parse("2022-11-09T00:00:00+00:00").to_month_day).to eql MonthDay.parse("11-09")
    end
  end

  describe "#to_zoned_date_time" do
    it "returns self" do
      now = described_class.now
      expect(now.to_zoned_date_time).to be now
    end
  end

  describe "#yesterday?" do
    it "returns true if the date is yesterday" do
      now = ZonedDateTime.now
      expect(now.yesterday?).to be false
      expect((now + 1.day).yesterday?).to be false
      expect((now - 1.day).yesterday?).to be true
      expect((now - 1.day).with(LocalTime::MIDNIGHT).yesterday?).to be true
      expect((now - 1.day).with(LocalTime::NOON).yesterday?).to be true
      expect((now - 1.day).with(LocalTime.parse("23:59:59")).yesterday?).to be true
    end
  end

  describe "#today?" do
    it "returns true if the date is today" do
      -12.upto(12) do |offset|
        now = ZonedDateTime.now.with_zone_same_instant(java.time.ZoneOffset.of_hours(offset))
        expect(now.today?).to be true
        expect((now + 1.day).today?).to be false
        expect((now - 1.day).today?).to be false
      end
    end
  end

  describe "#tomorrow?" do
    it "returns true if the date is tomorrow" do
      now = ZonedDateTime.now
      expect(now.tomorrow?).to be false
      expect((now + 1.day).tomorrow?).to be true
      expect((now - 1.day).tomorrow?).to be false
      expect((now + 1.day).with(LocalTime::MIDNIGHT).tomorrow?).to be true
      expect((now + 1.day).with(LocalTime::NOON).tomorrow?).to be true
      expect((now + 1.day).with(LocalTime.parse("23:59:59")).tomorrow?).to be true
    end
  end

  describe "#<=>" do
    let(:zdt) { described_class.parse("2022-11-09T02:09:05+00:00") }

    context "with a Time" do
      let(:time) { zdt.to_time }

      specify { expect(zdt).to eq time }
      specify { expect(zdt).not_to eql time }
      specify { expect(zdt).to be <= time }
      specify { expect(zdt).not_to be <= (time - 1) }
      specify { expect(zdt).to be >= time }
      specify { expect(zdt).not_to be >= (time + 1) }
      specify { expect(zdt).not_to be < time }
      specify { expect(zdt).to be < (time + 1) }
      specify { expect(zdt).not_to be > time }
      specify { expect(zdt).to be > (time - 1) }
    end

    context "with a Date" do
      let(:date) { Date.new(2022, 11, 9) }

      specify { expect(zdt).not_to eq date }
      specify { expect(zdt).not_to eql date }
      specify { expect(zdt).to be <= (date + 1) }
      specify { expect(zdt).not_to be <= date }
      specify { expect(zdt).to be >= date }
      specify { expect(zdt).not_to be >= (date + 1) }
      specify { expect(zdt).not_to be < date }
      specify { expect(zdt).to be < (date + 1) }
      specify { expect(zdt).not_to be > (date + 1) }
      specify { expect(zdt).to be > date }
    end

    context "with a LocalDate" do
      let(:date) { java.time.LocalDate.parse("2022-11-09") }

      specify { expect(zdt).not_to eq date }
      specify { expect(zdt).not_to eql date }
      specify { expect(zdt).to be <= (date + 1.day) }
      specify { expect(zdt).not_to be <= date }
      specify { expect(zdt).to be >= date }
      specify { expect(zdt).not_to be >= (date + 1.day) }
      specify { expect(zdt).not_to be < date }
      specify { expect(zdt).to be < (date + 1.day) }
      specify { expect(zdt).not_to be > (date + 1.day) }
      specify { expect(zdt).to be > date }
    end

    context "with a LocalTime" do
      let(:time) { LocalTime.parse("02:09:05") }

      specify { expect(zdt).to eq time }
      specify { expect(zdt).not_to eql time }
      specify { expect(zdt).to be <= time }
      specify { expect(zdt).not_to be <= (time - 1) }
      specify { expect(zdt).to be >= time }
      specify { expect(zdt).not_to be >= (time + 1) }
      specify { expect(zdt).not_to be < time }
      specify { expect(zdt).to be < (time + 1) }
      specify { expect(zdt).not_to be > time }
      specify { expect(zdt).to be > (time - 1) }
    end

    context "with a Month" do
      let(:oct) { java.time.Month::OCTOBER }
      let(:nov) { java.time.Month::NOVEMBER }
      let(:dec) { java.time.Month::DECEMBER }

      specify { expect(zdt).not_to eq nov }
      specify { expect(zdt).not_to eql nov }
      specify { expect(zdt).to be <= dec }
      specify { expect(zdt).not_to be <= nov }
      specify { expect(zdt).to be >= nov }
      specify { expect(zdt).not_to be >= dec }
      specify { expect(zdt).not_to be < nov }
      specify { expect(zdt).to be < dec }
      specify { expect(zdt).to be > nov }
      specify { expect(zdt).not_to be > dec }
    end

    context "with a MonthDay" do
      let(:date) { MonthDay.parse("11-09") }

      specify { expect(zdt).not_to eq date }
      specify { expect(zdt).not_to eql date }
      specify { expect(zdt).to be <= (date + 1.day) }
      specify { expect(zdt).not_to be <= date }
      specify { expect(zdt).to be >= date }
      specify { expect(zdt).not_to be >= (date + 1.day) }
      specify { expect(zdt).not_to be < date }
      specify { expect(zdt).to be < (date + 1.day) }
      specify { expect(zdt).to be > date }
      specify { expect(zdt).not_to be > (date + 1.day) }
    end
  end

  describe "#between?" do
    let(:zdt) { described_class.parse("2022-11-09T02:09:05+00:00") }

    it "works with min, max" do
      expect(zdt.between?("2022-10-01", "2022-12-01")).to be true
      expect(zdt.between?(zdt - 1.day, zdt + 1.day)).to be true
      expect(zdt.between?(zdt, zdt + 1.day)).to be true
      expect(zdt.between?(zdt - 1.day, zdt)).to be true
      expect(zdt.between?(zdt + 1.day, zdt + 2.days)).to be false
      expect(zdt.between?(zdt - 2.days, zdt - 1.day)).to be false
    end

    it "works with range" do
      expect(zdt.between?("2022-10-01".."2022-12-01")).to be true
      expect(zdt.between?("2022-11-09T02:09:05+00:00".."2022-12-01")).to be true
      expect(zdt.between?(zdt..(zdt + 1.day))).to be true
      expect(zdt.between?((zdt - 5.days)..zdt)).to be true
      expect(zdt.between?((zdt - 5.days)...zdt)).to be false
      expect(zdt.between?(zdt..)).to be true
    end
  end
end
