# frozen_string_literal: true

RSpec.describe Date do
  describe "#+" do
    it "works with Period and returns a LocalDate" do
      now = described_class.today
      expect(now + 1.day).to eq(now + 1)
      expect(now + 1.day).to be_a(java.time.LocalDate)
    end

    it "works with Time QuantityType and returns a LocalDate" do
      now = described_class.today
      expect(now + QuantityType.new("1 d")).to eq(now + 1)
      expect(now + QuantityType.new("1 d")).to be_a(java.time.LocalDate)
    end
  end

  describe "#-" do
    it "works with Period and returns a LocalDate" do
      now = described_class.today
      result = now - 1.day
      expect(result).to eq(now - 1)
      expect(result).to be_a(java.time.LocalDate)
    end

    it "works with LocalDate and returns a Period" do
      now = described_class.today
      ld = now.to_local_date.minus_days(1)
      result = now - ld
      expect(result).to eq(1.day)
      expect(result).to be_a(java.time.Period)
    end

    it "works with Time QuantityType and returns a LocalDate" do
      now = described_class.today
      result = now - QuantityType.new("1 d")
      expect(result).to eq(now - 1)
      expect(result).to be_a(java.time.LocalDate)
    end

    it "works with Numeric and returns a Date" do
      Timecop.freeze
      result = described_class.today - 1
      expect(result).to eql 1.day.ago.to_date
    end

    it "works with another Date and returns a Rational" do
      one_day = described_class.new(2002, 10, 31) - described_class.new(2002, 10, 30)
      expect(one_day).to eq(1)
      expect(one_day).to be_a(Rational)
    end
  end

  describe "#between?" do
    let(:date) { described_class.new(2022, 11, 9) }

    it "works with min, max" do
      expect(date.between?("2022-10-01", "2022-12-01")).to be true
      expect(date.between?(date - 1, date + 1)).to be true
      expect(date.between?(date, date + 1)).to be true
      expect(date.between?(date - 1, date)).to be true
      expect(date.between?(date + 1, date + 2)).to be false
      expect(date.between?(date - 2, date - 1)).to be false
    end

    it "works with range" do
      expect(date.between?("2022-10-01".."2022-12-01")).to be true
      expect(date.between?(date..(date + 1))).to be true
      expect(date.between?((date - 5)..date)).to be true
      expect(date.between?((date - 5)...date)).to be false
      expect(date.between?(date..)).to be true
    end
  end
end
