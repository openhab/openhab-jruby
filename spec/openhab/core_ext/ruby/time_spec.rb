# frozen_string_literal: true

RSpec.describe Time do
  describe "#+" do
    it "works with Duration and returns a ZonedDateTime" do
      now = described_class.now
      result = now + 1.minute
      expect(result).to eq(now + 60)
      expect(result).to be_a(java.time.ZonedDateTime)
    end

    it "works with Time QuantityType and returns a ZonedDateTime" do
      now = described_class.now
      result = now + QuantityType.new("1 min")
      expect(result).to eq(now + 60)
      expect(result).to be_a(java.time.ZonedDateTime)
    end

    it "works with Numeric and returns a Time" do
      Timecop.freeze
      result = described_class.now + 60
      expect(result).to eq 60.seconds.from_now
      expect(result).to be_a(described_class)
    end
  end

  describe "#-" do
    it "works with Duration and returns a ZonedDateTime" do
      now = described_class.now
      result = now - 1.minute
      expect(result).to eq(now - 60)
      expect(result).to be_a(java.time.ZonedDateTime)
    end

    it "works with Time QuantityType and returns a ZonedDateTime" do
      now = described_class.now
      result = now - QuantityType.new("1 min")
      expect(result).to eq(now - 60)
      expect(result).to be_a(java.time.ZonedDateTime)
    end

    it "works with ZonedDateTime and returns a Duration" do
      now = described_class.now
      zdt = now.to_zoned_date_time.minus_minutes(1)
      result = now - zdt
      expect(result).to eq(1.minute)
      expect(result).to be_a(java.time.Duration)
    end

    it "works with Numeric and returns a Time" do
      Timecop.freeze
      result = described_class.now - 60
      expect(result).to eq 60.seconds.ago
      expect(result).to be_a(described_class)
    end

    it "works with another Time and returns a Float" do
      one_day_in_secs = described_class.new(2002, 10, 31) - described_class.new(2002, 10, 30)
      expect(one_day_in_secs).to eq(86_400)
      expect(one_day_in_secs).to be_a(Numeric)
    end
  end

  describe "#between?" do
    let(:time) { described_class.new(2022, 11, 9, 2, 9, 5, "+00:00") }

    it "works with min, max" do
      expect(time.between?("2022-10-01", "2022-12-01")).to be true
      expect(time.between?(time - 1, time + 1)).to be true
      expect(time.between?(time, time + 1)).to be true
      expect(time.between?(time - 1, time)).to be true
      expect(time.between?(time + 1, time + 2)).to be false
      expect(time.between?(time - 2, time - 1)).to be false
    end

    it "works with range" do
      expect(time.between?("2022-10-01".."2022-12-01")).to be true
      expect(time.between?("2022-11-09T02:09:05+00:00".."2022-12-01")).to be true
      expect(time.between?(time..(time + 1))).to be true
      expect(time.between?((time - 5)..time)).to be true
      expect(time.between?((time - 5)...time)).to be false
      expect(time.between?(time..)).to be true
    end
  end

  describe "#to_instant" do
    it "converts to Instant" do
      expect(described_class.now.to_instant).to be_a(java.time.Instant)
    end
  end
end
