# frozen_string_literal: true

RSpec.describe OpenHAB::CoreExt::Ephemeris do
  let(:holidays_gb) do
    # @deprecated OH 4.1 Ephemeris holiday file format changed in openHAB 4.2
    file = if OpenHAB::Core.version >= OpenHAB::Core::V4_2
             "Holidays_gb.xml"
           else
             "Holidays_gb_4.1.xml"
           end
    fixture(file)
  end

  describe "#holiday" do
    it "returns a specific holiday" do
      expect(MonthDay.parse("12-25").holiday).to be :christmas
    end

    it "returns nil for a non-holiday" do
      expect(LocalDate.parse("2022-12-27").holiday).to be_nil
    end
  end

  describe "#holiday_name" do
    it "returns a specific holiday" do
      expect(Ephemeris.holiday_name(MonthDay.parse("12-25").holiday)).to eq "Christmas"
    end

    it "returns nil for a non-holiday" do
      expect(Ephemeris.holiday_name(nil)).to be_nil
    end

    it "works for religous holidays" do
      holiday = LocalDate.parse("2023-04-07").holiday(holidays_gb)
      expect(holiday).to be :"christian.good_friday"
      expect(Ephemeris.holiday_name(holiday)).to eq "Good Friday"
    end

    it "accepts a simple date" do
      expect(Ephemeris.holiday_name(MonthDay.parse("12-25"))).to eq "Christmas"
    end
  end

  describe "#next_holiday" do
    it "returns the exact holiday" do
      expect(MonthDay.parse("12-25").next_holiday).to be :christmas
    end

    it "returns the subsequent holiday" do
      expect(MonthDay.parse("12-23").next_holiday).to be :christmas
    end
  end

  describe "#holiday?" do
    it "returns true on a specific holiday" do
      expect(MonthDay.parse("12-25")).to be_holiday
    end

    it "returns false for a non-holiday" do
      expect(MonthDay.parse("12-23")).not_to be_holiday
    end
  end

  describe "#days_until" do
    it "returns the count until a specific holiday" do
      expect(MonthDay.parse("12-24").days_until(:christmas)).to be 1
    end

    it "returns 0 on the holiday" do
      expect(MonthDay.parse("12-25").days_until(:christmas)).to be 0
    end

    it "raises on an unrecognized holiday" do
      expect { Time.now.days_until(:my_birthday) }.to raise_error(ArgumentError, include("MY_BIRTHDAY"))
    end
  end

  describe "#weekend?" do
    it "returns true on a Saturday" do
      expect(LocalDate.parse("2022-12-10")).to be_weekend
    end

    it "returns false on a Tuesday" do
      expect(LocalDate.parse("2022-12-13")).not_to be_weekend
    end
  end

  describe "#in_dayset?" do
    it "returns false for an unrecognized dayset" do
      expect(Time.now.in_dayset?("unrecognized")).to be false
    end
  end

  context "with a holiday file set" do
    around do |spec|
      holiday_file(holidays_gb, &spec)
    end

    it "uses the file" do
      # a holiday that exists in England, but not the US
      boxing_day = LocalDate.parse("2023-12-26")
      expect(boxing_day.holiday).to be :boxing_day
      expect(boxing_day).to be_holiday
      expect(boxing_day.next_holiday).to be :boxing_day
      expect(boxing_day.days_until(:boxing_day)).to be 0
    end
  end
end
