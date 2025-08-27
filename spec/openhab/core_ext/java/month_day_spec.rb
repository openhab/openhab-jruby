# frozen_string_literal: true

RSpec.describe java.time.MonthDay do
  let(:date) { described_class.parse("11-09") }

  describe "#+" do
    it "works with a Period" do
      expect(date + 1.year).to eql MonthDay.parse("11-09")
      expect(date + 1.day).to eql MonthDay.parse("11-10")
    end

    it "works with Duration" do
      expect(date + 24.hours).to eql MonthDay.parse("11-10")
    end

    it "works with integers" do
      expect(date + 1).to eql MonthDay.parse("11-10")
    end
  end

  describe "#-" do
    it "works with a Period" do
      expect(date - 1.year).to eql MonthDay.parse("11-09")
      expect(date - 1.day).to eql MonthDay.parse("11-08")
    end

    it "works with Duration" do
      expect(date - 24.hours).to eql MonthDay.parse("11-08")
    end

    it "works with integers" do
      expect(date - 1).to eql MonthDay.parse("11-08")
    end

    it "returns a Period for another MonthDay instance" do
      expect(date - (date - 1)).to eql 1.day
    end

    it "returns a Period for a Date instance" do
      expect(date - Date.new(2022, 11, 8)).to eql 1.day
    end
  end

  describe "#to_month" do
    it "works" do
      expect(date.to_month).to eql java.time.Month::NOVEMBER
    end
  end

  describe "#to_month_day" do
    it "works" do
      expect(date.to_month_day).to be date
    end
  end

  describe "#to_local_date" do
    it "works" do
      expect(date.to_local_date(java.time.LocalDate.parse("2022-11-10"))).to eql java.time.LocalDate.parse("2022-11-09")
    end
  end

  describe "#to_zoned_date_time" do
    it "takes on the zone of the contextual date" do
      context = ZonedDateTime.parse("1990-05-04T03:02:01+03:00")
      expect(date.to_zoned_date_time(context)).to eql ZonedDateTime.parse("1990-11-09T00:00:00+03:00")
    end
  end

  describe "#to_instant" do
    it "takes on the year of the contextual date" do
      context = ZonedDateTime.parse("1990-05-04T03:02:01+03:00")
      expect(date.to_instant(context)).to eql Instant.parse("1990-11-09T00:00:00Z")
    end
  end

  describe "#succ" do
    it "works" do
      expect(date.succ).to eql MonthDay.parse("11-10")
    end

    it "rolls to the next month" do
      expect(MonthDay.parse("11-30").succ).to eql MonthDay.parse("12-01")
      expect(MonthDay.parse("02-28").succ).to eql MonthDay.parse("02-29")
      expect(MonthDay.parse("02-29").succ).to eql MonthDay.parse("03-01")
    end

    it "rolls to the next year" do
      expect(MonthDay.parse("12-31").succ).to eql MonthDay.parse("01-01")
    end
  end

  describe "#<=>" do
    context "with a MonthDay" do
      let(:other) { MonthDay.parse("11-09") }

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

    context "with a LocalDate" do
      let(:other) { java.time.LocalDate.parse("2022-11-09") }

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

  describe "in a range" do
    let(:yesterday) { MonthDay.now - 1 }
    let(:tomorrow) { MonthDay.now + 1 }
    let(:plus10) { MonthDay.now + 10 }
    let(:minus10) { MonthDay.now - 10 }
    let(:plus20) { MonthDay.now + 20 }
    let(:minus20) { MonthDay.now - 20 }

    # normal ranges
    specify { expect(between("12-01".."12-05").cover?(MonthDay.parse("01-20"))).to be false }
    specify { expect(between("12-01".."12-05").cover?(MonthDay.parse("12-01"))).to be true }
    specify { expect(between("12-01".."12-05").cover?(MonthDay.parse("12-03"))).to be true }
    specify { expect(between("12-01".."12-05").cover?(MonthDay.parse("12-05"))).to be true }
    specify { expect(between("12-01"..."12-05").cover?(MonthDay.parse("12-05"))).to be false }
    specify { expect(between("12-01".."12-05").cover?(MonthDay.parse("12-06"))).to be false }

    # same day ranges
    specify { expect(between("12-02".."12-02").cover?(MonthDay.parse("12-01"))).to be false }
    specify { expect(between("12-02".."12-02").cover?(MonthDay.parse("12-02"))).to be true }
    specify { expect(between("12-02".."12-02").cover?(MonthDay.parse("12-03"))).to be false }

    # leap years
    specify { expect(between("02-01".."03-01").cover?(MonthDay.parse("02-29"))).to be true }
    specify { expect(between("02-01"..."03-01").cover?(MonthDay.parse("02-29"))).to be true }

    # spanning months
    specify { expect(between("01-25".."02-05").cover?(MonthDay.parse("02-03"))).to be true }
    specify { expect(between("01-25".."02-05").cover?(MonthDay.parse("11-25"))).to be false }

    # spanning end of year
    specify { expect(between("12-01".."01-05").cover?(MonthDay.parse("11-25"))).to be false }
    specify { expect(between("12-01".."01-05").cover?(MonthDay.parse("12-01"))).to be true }
    specify { expect(between("12-01".."01-05").cover?(MonthDay.parse("12-25"))).to be true }
    specify { expect(between("12-01".."01-05").cover?(MonthDay.parse("01-01"))).to be true }
    specify { expect(between("12-01".."01-05").cover?(MonthDay.parse("01-05"))).to be true }
    specify { expect(between("12-01"..."01-05").cover?(MonthDay.parse("01-05"))).to be false }
    specify { expect(between("12-01".."01-05").cover?(MonthDay.parse("01-20"))).to be false }

    # against Date
    specify { expect((yesterday..tomorrow).cover?(Date.today)).to be true }
    specify { expect((plus10..plus20).cover?(Date.today)).to be false }
    specify { expect((minus20..minus10).cover?(Date.today)).to be false }

    # other types
    specify { expect((yesterday..tomorrow).cover?(Time.now)).to be true }
    specify { expect((yesterday..tomorrow).cover?(DateTime.now)).to be true } # rubocop:disable Style/DateTime
    specify { expect((yesterday..tomorrow).cover?(MonthDay.now)).to be true }
  end

  describe "#between?" do
    it "works with min, max" do
      expect(date.between?(date - 1.day, date + 1.day)).to be true
      expect(date.between?(date, date + 1.day)).to be true
      expect(date.between?(date - 1.day, date)).to be true
      expect(date.between?("11-08", "12-01")).to be true
      expect(date.between?(date + 1.day, date + 2.days)).to be false
      expect(date.between?(date - 2.days, date - 1.day)).to be false
    end

    it "works with range" do
      expect(date.between?("11-08".."12-01")).to be true
      expect(date.between?(date..(date + 1.day))).to be true
      expect(date.between?((date - 5.days)..date)).to be true
      expect(date.between?((date - 5.days)...date)).to be false
      expect(date.between?(date..)).to be true
    end
  end
end
