# frozen_string_literal: true

RSpec.describe DateTime do
  describe "#+" do
    it "works with Duration" do
      now = described_class.now
      expect(now + 1.day).to eq(now + 1)
    end
  end

  describe "#-" do
    it "works with Duration and returns a ZonedDateTime" do
      now = described_class.now
      result = now - 1.day
      expect(result).to eq(now - 1)
      expect(result).to be_a(java.time.ZonedDateTime)
    end

    it "works with ZonedDateTime and returns a Duration" do
      now = described_class.now
      zdt = now.to_zoned_date_time.minus_minutes(1)
      result = now - zdt
      expect(result).to eq(1.minute)
      expect(result).to be_a(java.time.Duration)
    end

    it "works with Numeric and returns a DateTime" do
      result = described_class.new(2022, 1, 1, 13, 30, 30) - 1
      expect(result).to eql described_class.new(2021, 12, 31, 13, 30, 30)
    end

    it "works with another DateTime and returns a Float" do
      one_day_in_secs = described_class.new(2002, 10, 31) - described_class.new(2002, 10, 30)
      expect(one_day_in_secs).to eq(1)
      expect(one_day_in_secs).to be_a(Rational)
    end
  end

  describe "#between?" do
    let(:dt) { described_class.new(2022, 11, 9, 2, 9, 5, "+00:00") }

    it "works with min, max" do
      expect(dt.between?("2022-10-01", "2022-12-01")).to be true
      expect(dt.between?(dt - 1, dt + 1)).to be true
      expect(dt.between?(dt, dt + 1)).to be true
      expect(dt.between?(dt - 1, dt)).to be true
      expect(dt.between?(dt + 1, dt + 2)).to be false
      expect(dt.between?(dt - 2, dt - 1)).to be false
    end

    it "works with range" do
      expect(dt.between?("2022-10-01".."2022-12-01")).to be true
      expect(dt.between?("2022-11-09T02:09:05+00:00".."2022-12-01")).to be true
      expect(dt.between?(dt..(dt + 1))).to be true
      expect(dt.between?((dt - 5)..dt)).to be true
      expect(dt.between?((dt - 5)...dt)).to be false
      expect(dt.between?(dt..)).to be true
    end
  end
end
