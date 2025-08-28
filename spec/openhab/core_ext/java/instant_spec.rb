# frozen_string_literal: true

RSpec.describe java.time.Instant do
  describe "#to_i" do
    it "returns epoch seconds" do
      now = Time.now
      expect(now.to_instant.to_i).to be now.to_i
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

    it "returns an Instant" do
      now = described_class.now
      expect(now + 5).to be_a(described_class)
      expect(now + 5.seconds).to be_a(described_class)
    end
  end

  describe "#-" do
    it "works with duration" do
      now = described_class.now
      expect((now - 5.seconds).to_i).to be(now.to_i - 5)
      expect((now - 2.minutes).to_i).to be(now.to_i - 120)
      expect(now - 1.second).to be_a(described_class)
    end

    it "works with integers" do
      now = described_class.now
      expect((now - 5).to_i).to be(now.to_i - 5)
      expect(now - 5).to be_a(described_class)
    end

    it "returns a duration for another Instant instance" do
      now = described_class.now
      future = now + 5.seconds
      expect(future - now).to eql 5.seconds
    end

    it "returns a duration for a ZonedDateTime instance" do
      now = described_class.now
      future = now + 5.seconds
      expect(future - now.to_zoned_date_time).to eql 5.seconds
    end

    it "returns a duration for a Time instance" do
      now = described_class.now
      future = (now + 5.seconds)
      expect(future - now.to_time).to eql 5.seconds
    end
  end

  describe "#to_date" do
    it "works" do
      expect(described_class.parse("2022-11-09T02:09:05Z").to_date).to eql Date.new(2022, 11, 9)
    end
  end

  describe "#to_local_date" do
    it "works" do
      expect(described_class.parse("2022-11-09T02:09:05Z").to_local_date)
        .to eql java.time.LocalDate.parse("2022-11-09")
    end
  end

  describe "#to_local_time" do
    it "works" do
      expect(described_class.parse("2022-11-09T02:09:05Z").to_local_time)
        .to eql LocalTime.parse("02:09:05")
    end
  end

  describe "#to_month" do
    it "works" do
      expect(described_class.parse("2022-11-09T00:00:00Z").to_month).to eql java.time.Month::NOVEMBER
    end
  end

  describe "#to_month_day" do
    it "works" do
      expect(described_class.parse("2022-11-09T00:00:00Z").to_month_day).to eql MonthDay.parse("11-09")
    end
  end

  describe "#yesterday?" do
    it "returns true if the date is yesterday" do
      now = described_class.now
      expect(now.yesterday?).to be false
      expect((now + 1.day).yesterday?).to be false
      expect((now - 1.day).yesterday?).to be true
      midnight = LocalTime::MIDNIGHT.to_zoned_date_time.to_instant
      expect((midnight - 1.day).yesterday?).to be true
      expect((midnight - 1.second).yesterday?).to be true
      expect((midnight + 1.day).yesterday?).to be false
    end
  end

  describe "#today?" do
    it "returns true if the date is today" do
      now = described_class.now
      expect(now.today?).to be true
      expect((now + 1.day).today?).to be false
      expect((now - 1.day).today?).to be false
      midnight = LocalTime::MIDNIGHT.to_zoned_date_time.to_instant
      expect(midnight.today?).to be true
      expect((midnight - 1.second).today?).to be false
      expect((midnight + 1.day).today?).to be false
      expect((midnight + 1.day - 1.second).today?).to be true
    end
  end

  describe "#tomorrow?" do
    it "returns true if the date is tomorrow" do
      now = described_class.now
      expect(now.tomorrow?).to be false
      expect((now + 1.day).tomorrow?).to be true
      expect((now - 1.day).tomorrow?).to be false
      midnight = LocalTime::MIDNIGHT.to_zoned_date_time.to_instant
      expect((midnight + 1.day).tomorrow?).to be true
      expect((midnight + 1.day - 1.second).tomorrow?).to be false
      expect((midnight + 2.days - 1.second).tomorrow?).to be true
    end
  end

  describe "#to_zoned_date_time" do
    it "works" do
      now = described_class.now
      expect(now.to_zoned_date_time).to be_a(java.time.ZonedDateTime)
    end
  end

  describe "#<=>" do
    let(:instant) { described_class.parse("2022-11-09T02:09:05Z") }

    context "with a ZonedDateTime" do
      let(:time) { instant.to_zoned_date_time.with_zone_same_instant(java.time.ZoneId.of("UTC+10")) }

      specify { expect(instant).to eq time }
      specify { expect(instant).not_to eql time }
      specify { expect(instant).to be <= time }
      specify { expect(instant).not_to be <= (time - 1.second) }
      specify { expect(instant).to be >= time }
      specify { expect(instant).not_to be >= (time + 1.second) }
      specify { expect(instant).not_to be < time }
      specify { expect(instant).to be < (time + 1.second) }
      specify { expect(instant).not_to be > time }
      specify { expect(instant).to be > (time - 1.second) }
    end

    context "with a Time" do
      let(:time) { instant.to_time }

      specify { expect(instant).to eq time }
      specify { expect(instant).not_to eql time }
      specify { expect(instant).to be <= time }
      specify { expect(instant).not_to be <= (time - 1) }
      specify { expect(instant).to be >= time }
      specify { expect(instant).not_to be >= (time + 1) }
      specify { expect(instant).not_to be < time }
      specify { expect(instant).to be < (time + 1) }
      specify { expect(instant).not_to be > time }
      specify { expect(instant).to be > (time - 1) }
    end

    context "with a Date" do
      let(:date) { Date.new(2022, 11, 9) }

      specify { expect(instant).not_to eq date }
      specify { expect(instant).not_to eql date }
      specify { expect(instant).to be <= (date + 1) }
      specify { expect(instant).not_to be <= date }
      specify { expect(instant).to be >= date }
      specify { expect(instant).not_to be >= (date + 1) }
      specify { expect(instant).not_to be < date }
      specify { expect(instant).to be < (date + 1) }
      specify { expect(instant).not_to be > (date + 1) }
      specify { expect(instant).to be > date }
    end

    context "with a LocalDate" do
      let(:date) { java.time.LocalDate.parse("2022-11-09") }

      specify { expect(instant).not_to eq date }
      specify { expect(instant).not_to eql date }
      specify { expect(instant).to be <= (date + 1.day) }
      specify { expect(instant).not_to be <= date }
      specify { expect(instant).to be >= date }
      specify { expect(instant).not_to be >= (date + 1.day) }
      specify { expect(instant).not_to be < date }
      specify { expect(instant).to be < (date + 1.day) }
      specify { expect(instant).not_to be > (date + 1.day) }
      specify { expect(instant).to be > date }
    end

    context "with a LocalTime" do
      let(:time) { LocalTime.parse("02:09:05") }

      specify { expect(instant).to eq time }
      specify { expect(instant).not_to eql time }
      specify { expect(instant).to be <= time }
      specify { expect(instant).not_to be <= (time - 1) }
      specify { expect(instant).to be >= time }
      specify { expect(instant).not_to be >= (time + 1) }
      specify { expect(instant).not_to be < time }
      specify { expect(instant).to be < (time + 1) }
      specify { expect(instant).not_to be > time }
      specify { expect(instant).to be > (time - 1) }
    end

    context "with a Month" do
      let(:oct) { java.time.Month::OCTOBER }
      let(:nov) { java.time.Month::NOVEMBER }
      let(:dec) { java.time.Month::DECEMBER }

      specify { expect(instant).not_to eq nov }
      specify { expect(instant).not_to eql nov }
      specify { expect(instant).to be <= dec }
      specify { expect(instant).not_to be <= nov }
      specify { expect(instant).to be >= nov }
      specify { expect(instant).not_to be >= dec }
      specify { expect(instant).not_to be < nov }
      specify { expect(instant).to be < dec }
      specify { expect(instant).to be > nov }
      specify { expect(instant).not_to be > dec }
    end

    context "with a MonthDay" do
      let(:date) { MonthDay.parse("11-09") }

      specify { expect(instant).not_to eq date }
      specify { expect(instant).not_to eql date }
      specify { expect(instant).to be <= (date + 1.day) }
      specify { expect(instant).not_to be <= date }
      specify { expect(instant).to be >= date }
      specify { expect(instant).not_to be >= (date + 1.day) }
      specify { expect(instant).not_to be < date }
      specify { expect(instant).to be < (date + 1.day) }
      specify { expect(instant).to be > date }
      specify { expect(instant).not_to be > (date + 1.day) }
    end
  end

  describe "#between?" do
    let(:instant) { described_class.parse("2022-11-09T02:09:05Z") }

    it "works with min, max" do
      expect(instant.between?("2022-10-01", "2022-12-01")).to be true
      expect(instant.between?(instant - 1.day, instant + 1.day)).to be true
      expect(instant.between?(instant, instant + 1.day)).to be true
      expect(instant.between?(instant - 1.day, instant)).to be true
      expect(instant.between?(instant + 1.day, instant + 2.days)).to be false
      expect(instant.between?(instant - 2.days, instant - 1.day)).to be false
    end

    it "works with range" do
      expect(instant.between?("2022-10-01".."2022-12-01")).to be true
      expect(instant.between?("2022-11-09T02:09:05Z".."2022-12-01")).to be true
      expect(instant.between?(instant..(instant + 1.day))).to be true
      expect(instant.between?((instant - 5.days)..instant)).to be true
      expect(instant.between?((instant - 5.days)...instant)).to be false
      expect(instant.between?(instant..)).to be true
    end
  end
end
