# frozen_string_literal: true

RSpec.describe Duration do
  it "is constructible from various numbers" do
    expect(5.seconds).to be_a(described_class)
    expect(5.minutes).to be_a(described_class)
    expect(5.hours).to be_a(described_class)
    expect(5.5.seconds).to be_a(described_class)
    expect(5.5.minutes).to be_a(described_class)
    expect(5.5.hours).to be_a(described_class)
  end

  describe "comparisons" do
    it "works with numeric" do
      expect(5.seconds).to eq 5
      expect(1.minute).to eq 60
      expect(5.seconds < 6).to be true
      expect(5.seconds > 6).to be false
      expect(5.seconds > 4).to be true
      expect(5.seconds < 4).to be false
    end

    it "works with other Durations" do
      expect(60.seconds).to eq 1.minute
      expect(5.seconds < 6.seconds).to be true
      expect(5.seconds > 6.seconds).to be false
      expect(5.seconds > 4.seconds).to be true
      expect(5.seconds < 4.seconds).to be false
    end

    it "works with Time QuantityType" do
      expect(QuantityType.new("5 s") == 5.seconds).to be true
      expect(QuantityType.new("1 min") == 60.seconds).to be true
      expect(QuantityType.new("5 s") < 6.seconds).to be true
      expect(QuantityType.new("5 s") > 6.seconds).to be false
      expect(QuantityType.new("5 s") > 4.seconds).to be true
      expect(QuantityType.new("5 s") < 4.seconds).to be false

      expect(5.seconds == QuantityType.new("5 s")).to be true
      expect(60.seconds == QuantityType.new("1 min")).to be true
      expect(6.seconds > QuantityType.new("5 s")).to be true
      expect(6.seconds < QuantityType.new("5 s")).to be false
      expect(4.seconds < QuantityType.new("5 s")).to be true
      expect(4.seconds > QuantityType.new("5 s")).to be false
    end
  end

  describe "math operations" do
    describe "additions and subtractions" do
      it "works with other Duration" do
        expect(1.hour + 5.minutes).to eql 65.minutes
        expect(1.hour - 5.minutes).to eql 55.minutes
      end

      it "works with Period and returns a Duration" do
        expect(5.hours + Period.of_days(1)).to eql 29.hours
        expect(25.hours - Period.of_days(1)).to eql 1.hours
        expect(Period.of_days(1) + 5.hours).to eql 29.hours
        expect(Period.of_days(1) - 5.hours).to eql 19.hours
      end

      it "works with Numeric" do
        expect(60.seconds + 5).to eql 65.seconds
        expect(5 + 60.seconds).to eql 65.seconds
        expect(60.seconds - 5).to eql 55.seconds
        expect(60 - 5.seconds).to eql 55.seconds
      end

      it "works with Time QuantityType and returns a Duration" do
        expect(1.second + QuantityType.new("5 s")).to eql 6.seconds
        expect(5.seconds - QuantityType.new("1 s")).to eql 4.seconds
      end

      it "Time QuantityType works with Duration and returns a QuantityType" do
        expect(QuantityType.new("5 s") + 1.second).to eql QuantityType.new("6 s")
        expect(QuantityType.new("5 s") - 1.second).to eql QuantityType.new("4 s")
      end
    end

    describe "multiplications and divisions" do
      it "works with Numeric" do
        expect(5.minutes * 2).to eql 10.minutes
        expect(5.minutes / 2).to eql 2.5.minutes
        expect(5.minutes * 2.5).to eql 12.5.minutes
        expect(5.minutes / 2.5).to eql 2.minutes
      end
    end
  end

  describe "#to_i" do
    it "returns seconds" do
      expect(5.seconds.to_i).to be 5
      expect(1.minute.to_i).to be 60
    end
  end

  describe "#ago" do
    it "works" do
      Timecop.freeze
      now = ZonedDateTime.now
      expect(5.minutes.ago).to eql now - 5.minutes
    end
  end

  describe "#from_now" do
    it "works" do
      Timecop.freeze
      now = ZonedDateTime.now
      expect(5.minutes.from_now).to eql now + 5.minutes
    end
  end

  describe "#between?" do
    it "works with min, max" do
      expect(10.seconds.between?(1.second, 1.hour)).to be true
      expect(10.seconds.between?(10.seconds, 1.hour)).to be true
      expect(10.seconds.between?(1.second, 10.seconds)).to be true
      expect(10.seconds.between?(1.second, 5.seconds)).to be false
      expect(10.seconds.between?(1.hour, 2.hours)).to be false
    end

    it "works with range" do
      expect(10.seconds.between?((1.second)..(1.hour))).to be true
      expect(10.seconds.between?((1.second)..(10.seconds))).to be true
      expect(10.seconds.between?((1.second)...(10.seconds))).to be false
      expect(10.seconds.between?((1.second)..)).to be true
    end
  end
end
