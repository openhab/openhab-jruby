# frozen_string_literal: true

RSpec.describe java.time.LocalDate do
  let(:date) { described_class.parse("2022-11-09") }

  describe "#+" do
    it "works with a Period" do
      expect(date + 1.year).to eql java.time.LocalDate.parse("2023-11-09")
      expect(date + 1.day).to eql java.time.LocalDate.parse("2022-11-10")
    end

    it "works with Duration" do
      expect(date + 24.hours).to eql java.time.LocalDate.parse("2022-11-10")
    end

    it "works with integers" do
      expect(date + 1).to eql java.time.LocalDate.parse("2022-11-10")
    end
  end

  describe "#-" do
    it "works with a Period" do
      expect(date - 1.year).to eql java.time.LocalDate.parse("2021-11-09")
      expect(date - 1.day).to eql java.time.LocalDate.parse("2022-11-08")
    end

    it "works with Duration" do
      expect(date - 24.hours).to eql java.time.LocalDate.parse("2022-11-08")
    end

    it "works with integers" do
      expect(date - 1).to eql java.time.LocalDate.parse("2022-11-08")
    end

    it "returns a Period for another LocalDate instance" do
      expect(date - (date - 1)).to eql 1.day
      expect(date - java.time.LocalDate.of(2021, 11, 9)).to eql 1.year
    end

    it "returns a Period for a Date instance" do
      expect(date - Date.new(2022, 11, 8)).to eql 1.day
      expect(date - Date.new(2021, 11, 9)).to eql 1.year
    end
  end

  describe "#to_date" do
    it "works" do
      expect(date.to_date).to eql Date.new(2022, 11, 9)
    end
  end

  describe "#to_month" do
    it "works" do
      expect(date.to_month).to eql java.time.Month::NOVEMBER
    end
  end

  describe "#to_month_day" do
    it "works" do
      expect(date.to_month_day).to eql MonthDay.parse("11-09")
    end
  end

  describe "#to_local_date" do
    it "returns self" do
      expect(date.to_local_date).to be date
    end
  end

  describe "#to_zoned_date_time" do
    it "takes on the zone of the contextual date" do
      context = ZonedDateTime.parse("1990-05-04T03:02:01+03:00")
      expect(date.to_zoned_date_time(context)).to eql ZonedDateTime.parse("2022-11-09T00:00:00+03:00")
    end
  end

  describe "#succ" do
    it "works" do
      expect(date.succ).to eql java.time.LocalDate.parse("2022-11-10")
    end

    it "rolls to the next month" do
      expect(java.time.LocalDate.parse("2022-11-30").succ).to eql java.time.LocalDate.parse("2022-12-01")
      expect(java.time.LocalDate.parse("2022-02-28").succ).to eql java.time.LocalDate.parse("2022-03-01")
    end

    it "doesn't roll to the next month on leap year" do
      expect(java.time.LocalDate.parse("2020-02-28").succ).to eql java.time.LocalDate.parse("2020-02-29")
    end

    it "rolls to the next year" do
      expect(java.time.LocalDate.parse("2022-12-31").succ).to eql java.time.LocalDate.parse("2023-01-01")
    end
  end

  describe "#<=>" do
    context "with a LocalDate" do
      let(:other) { java.time.LocalDate.parse("2022-11-09") }

      specify { expect(date).to eq other }
      specify { expect(date).to eql other }
      specify { expect(date).to be <= other }
      specify { expect(date).not_to be <= (other - 1.day) }
      specify { expect(date).to be >= other }
      specify { expect(date).not_to be >= (other + 1.day) }
      specify { expect(date).not_to be < other }
      specify { expect(date).to be < (other + 1.day) }
      specify { expect(date).not_to be > other }
      specify { expect(date).to be > (other - 1.day) }
    end

    context "with a Date" do
      let(:other) { Date.new(2022, 11, 9) }

      specify { expect(date).to eq other }
      specify { expect(date).not_to eql other }
      specify { expect(date).to be <= other }
      specify { expect(date).not_to be <= (other - 1) }
      specify { expect(date).to be >= other }
      specify { expect(date).not_to be >= (other + 1) }
      specify { expect(date).not_to be < other }
      specify { expect(date).to be < (other + 1) }
      specify { expect(date).not_to be > other }
      specify { expect(date).to be > (other - 1) }
    end

    context "with a Month" do
      let(:oct) { java.time.Month::OCTOBER }
      let(:nov) { java.time.Month::NOVEMBER }
      let(:dec) { java.time.Month::DECEMBER }

      specify { expect(date).to eq nov }
      specify { expect(date).not_to eql nov }
      specify { expect(date).to be <= nov }
      specify { expect(date).not_to be <= oct }
      specify { expect(date).to be >= nov }
      specify { expect(date).not_to be >= dec }
      specify { expect(date).not_to be < nov }
      specify { expect(date).to be < dec }
      specify { expect(date).not_to be > nov }
      specify { expect(date).to be > oct }
    end

    context "with a MonthDay" do
      let(:other) { MonthDay.parse("11-09") }

      specify { expect(date).to eq other }
      specify { expect(date).not_to eql other }
      specify { expect(date).to be <= date }
      specify { expect(date).not_to be <= (other - 1.day) }
      specify { expect(date).to be >= date }
      specify { expect(date).not_to be >= (other + 1.day) }
      specify { expect(date).not_to be < other }
      specify { expect(date).to be < (other + 1.day) }
      specify { expect(date).not_to be > other }
      specify { expect(date).to be > (other - 1.day) }
    end
  end

  describe "#between?" do
    it "works with min, max" do
      expect(date.between?("2022-10-01", "2022-12-01")).to be true
      expect(date.between?(date - 1.day, date + 1.day)).to be true
      expect(date.between?(date, date + 1.day)).to be true
      expect(date.between?(date - 1.day, date)).to be true
      expect(date.between?(date + 1.day, date + 2.days)).to be false
      expect(date.between?(date - 2.days, date - 1.day)).to be false
    end

    it "works with range" do
      expect(date.between?("2022-10-01".."2022-12-01")).to be true
      expect(date.between?(date..date + 1.day)).to be true
      expect(date.between?(date - 5.days..date)).to be true
      expect(date.between?(date - 5.days...date)).to be false
      expect(date.between?(date..)).to be true
    end

    it "checks for invalid arguments" do
      expect { date.between?((date..date + 1.day), date) }.to raise_exception(ArgumentError)
      expect { date.between?(date) }.to raise_exception(ArgumentError)
    end
  end
end
