# frozen_string_literal: true

RSpec.describe java.time.Month do
  let(:march) { described_class::MARCH }

  describe "#+" do
    it "works with integers" do
      expect(march + 1).to eql described_class::APRIL
      expect(march + 11).to eql described_class::FEBRUARY
    end
  end

  describe "#-" do
    it "works with integers" do
      expect(march - 1).to eql described_class::FEBRUARY
      expect(march - 3).to eql described_class::DECEMBER
    end
  end

  describe "#to_month" do
    it "works" do
      expect(march.to_month).to eql march
    end
  end

  describe "#to_month_day" do
    it "works" do
      expect(march.to_month_day).to eq MonthDay.of(3, 1)
    end
  end

  describe "#to_local_date" do
    it "works" do
      expect(march.to_local_date(java.time.LocalDate.parse("2022-11-10"))).to eq java.time.LocalDate.parse("2022-03-01")
    end
  end

  describe "#to_zoned_date_time" do
    it "takes on the zone of the contextual date" do
      context = ZonedDateTime.parse("1990-05-04T03:02:01+03:00")
      expect(march.to_zoned_date_time(context)).to eq ZonedDateTime.parse("1990-03-01T00:00:00+03:00")
    end
  end

  describe "#to_instant" do
    it "takes on the year of the contextual date" do
      context = ZonedDateTime.parse("1990-05-04T03:02:01+03:00")
      expect(march.to_instant(context)).to eq Instant.parse("1990-03-01T00:00:00Z")
    end
  end

  describe "#succ" do
    it "works" do
      expect(march.succ).to eql described_class::APRIL
    end

    it "rolls to the beginning of the year" do
      expect(described_class::DECEMBER.succ).to eql described_class::JANUARY
    end
  end

  describe "#between?" do
    it "works with min, max" do
      expect(march.between?(described_class::JANUARY, described_class::APRIL)).to be true
      expect(march.between?(march, described_class::APRIL)).to be true
      expect(march.between?(described_class::JANUARY, march)).to be true
      expect(march.between?(march, described_class::JANUARY)).to be true
      expect(march.between?(described_class::JANUARY, described_class::FEBRUARY)).to be false
      expect(march.between?(described_class::APRIL, described_class::MAY)).to be false
    end

    it "works with range" do
      expect(march.between?(described_class::JANUARY..described_class::APRIL)).to be true
      expect(march.between?(march..described_class::APRIL)).to be true
      expect(march.between?(described_class::JANUARY..march)).to be true
      expect(march.between?(described_class::JANUARY...march)).to be false
      expect(march.between?(march..described_class::JANUARY)).to be true
      expect(march.between?(described_class::JANUARY..described_class::FEBRUARY)).to be false
      expect(march.between?(described_class::APRIL..described_class::MAY)).to be false
    end
  end
end
