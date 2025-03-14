# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::QuantityType do
  it "is constructible with | from numeric" do
    expect(50 | "°F").to eql QuantityType.new("50.0 °F")
    expect(50.0 | "°F").to eql QuantityType.new("50.0 °F")
    expect(50.to_d | "°F").to eql QuantityType.new("50.0 °F")
  end

  describe "math operations" do
    describe "additions and subtractions" do
      it "support quantity type operand" do
        expect(QuantityType.new("50 °F") + QuantityType.new("50 °F")).to eql QuantityType.new("100.0 °F")
        expect(QuantityType.new("50 °F") - QuantityType.new("25 °F")).to eql QuantityType.new("25.0 °F")
        expect(QuantityType.new("50 °F") + -QuantityType.new("25 °F")).to eql QuantityType.new("25.0 °F")
      end

      it "raise exception with non QuantityType operand" do
        expect { QuantityType.new("50 °F") + 50 }.to raise_exception(TypeError)
        expect { QuantityType.new("50 °F") - 50 }.to raise_exception(TypeError)
        expect { 50 + QuantityType.new("50 °F") }.to raise_exception(javax.measure.UnconvertibleException)
        expect { 50 - QuantityType.new("50 °F") }.to raise_exception(javax.measure.UnconvertibleException)
      end
    end

    describe "multiplications and divisions" do
      it "support quantity type operand" do
        expect(QuantityType.new("100 W") * QuantityType.new("2 W")).to eql QuantityType.new("200 W²")
        expect(QuantityType.new("100 W") / QuantityType.new("2 W")).to eql QuantityType.new("50")
      end

      it "support numeric operand" do
        expect(QuantityType.new("50 W") * 2).to eql QuantityType.new("100.0 W")
        expect(QuantityType.new("50 kW") * 2).to eql QuantityType.new("100.0 kW")
        expect(2 * QuantityType.new("50 W")).to eql QuantityType.new("100.0 W")
        expect(2 * QuantityType.new("50 kW")).to eql QuantityType.new("100.0 kW")
        expect(QuantityType.new("100 W") / 2).to eql QuantityType.new("50.0 W")
        expect(QuantityType.new("50 W") * 2.0).to eql QuantityType.new("100.0 W")
        expect(2.0 * QuantityType.new("50 W")).to eql QuantityType.new("100.0 W")
        expect(2.0 * QuantityType.new("50 kW")).to eql QuantityType.new("100.0 kW")
        expect(QuantityType.new("100 W") / 2.0).to eql QuantityType.new("50.0 W")
      end

      it "support DecimalType operand" do
        expect(QuantityType.new("50 W") * DecimalType.new(2)).to eql QuantityType.new("100.0 W")
        expect(QuantityType.new("100 W") / DecimalType.new(2)).to eql QuantityType.new("50.0 W")
        expect(QuantityType.new("50 W") * DecimalType.new(2.0)).to eql QuantityType.new("100.0 W")
        expect(QuantityType.new("100 W") / DecimalType.new(2.0)).to eql QuantityType.new("50.0 W")
      end
    end

    describe "with mixed units" do
      it "normalizes units in complex expression" do
        expect(((23 | "°C") | "°F") - (70 | "°F")).to be < 4 | "°F"
      end

      it "supports arithmetic" do
        expect((20 | "°C") + (9 | "°F")).to eql 25 | "°C"
        expect((25 | "°C") - (9 | "°F")).to eql 20 | "°C"
      end

      it "works in a unit block" do
        unit("°C") do
          expect((20 | "°C") + (9 | "°F")).to eql 25 | "°C"
          expect((25 | "°C") - (9 | "°F")).to eql 20 | "°C"
        end
      end
    end
  end

  it "can be compared" do
    expect(QuantityType.new("50 °F")).to be > QuantityType.new("25 °F")
    expect(QuantityType.new("50 °F")).not_to be > QuantityType.new("525 °F")
    expect(QuantityType.new("50 °F")).to be >= QuantityType.new("25 °F")
    expect(QuantityType.new("50 °F")).to eq QuantityType.new("50 °F")
    expect(QuantityType.new("50 °F")).to be < QuantityType.new("25 °C")
  end

  it "responds to positive?, negative?, zero?, and nonzero?" do
    items.build do
      number_item "NumberF", state: "2 °F"
      number_item "NumberC", state: "2 °C"
      number_item "PowerPos", state: 100 | "W"
      number_item "PowerNeg", state: -100 | "W"
      number_item "PowerZero", state: 0 | "W"
      number_item "Number1", state: 20
    end

    expect(QuantityType.new("50°F")).to be_positive
    expect(QuantityType.new("-50°F")).to be_negative
    expect(QuantityType.new("10W")).to be_positive
    expect(QuantityType.new("-1kW")).not_to be_positive
    expect(QuantityType.new("0W")).to be_zero
    expect(NumberF).to be_positive
    expect(NumberC).not_to be_negative
    expect(PowerPos).to be_positive
    expect(PowerNeg).to be_negative
    expect(PowerNeg).to be_nonzero
    expect(PowerZero).to be_zero
    expect(PowerZero).not_to be_nonzero
    expect(Number1).to be_positive
    expect(Number1).to be_nonzero
  end

  it "converts to another unit with |" do
    expect((0 | "°C") | "°F").to eql QuantityType.new("32 °F")
    expect((1 | "h") | "s").to eql QuantityType.new("3600 s")
    expect((23 | "°C") | ImperialUnits::FAHRENHEIT).to eql QuantityType.new("73.4 °F")
    expect((((370 | "mired") | "K")).to_f.round).to be 2703
  end

  it "supports ranges" do
    expect((0 | "W")..(10 | "W")).to cover(0 | "W")
    expect((0 | "W")..(10 | "W")).not_to cover(14 | "W")
    expect((0 | "W")..(10 | "W")).to cover(10 | "W")
  end

  describe "#eql?" do
    it "returns false for invertible units" do
      expect(1 | "W").not_to eql(1 | "/W")
    end
  end

  describe "comparisons" do
    let(:ten_c) { QuantityType.new("10 °C") }
    let(:five_c) { QuantityType.new("5 °C") }
    let(:ten_f) { QuantityType.new("10 °F") }
    let(:fifty_f) { QuantityType.new("50 °F") }

    # QuantityType vs QuantityType
    specify { expect(ten_c).to eql ten_c }
    specify { expect(ten_c).to eq ten_c }
    specify { expect(ten_c != ten_c).to be false }
    specify { expect(ten_c).not_to eq ten_f }
    specify { expect(ten_c).to eq fifty_f }
    specify { expect(ten_c != ten_f).to be true }
    specify { expect(ten_c != QuantityType.new("10.1 °C")).to be true }
    specify { expect(ten_c != fifty_f).to be false }

    specify { expect(ten_c).to be > five_c }
    specify { expect(ten_c).to be > ten_f }
    specify { expect(ten_c).not_to be > fifty_f }
    specify { expect(five_c).to be < ten_c }
    specify { expect(QuantityType.new("20 °C")).not_to be < ten_c }
    specify { expect(five_c).to be < fifty_f }

    it "is not comparable against String" do
      expect { ten_c > "10 °F" }.to raise_exception(ArgumentError)
      expect(ten_f == "10 °F").to be false
      expect(ten_f == "10 °C").to be false
      expect(ten_f == "10").to be false
    end

    it "is not comparable against bare Numeric" do
      expect { ten_c > 3 }.to raise_exception(ArgumentError)
      expect(ten_c == 10).to be false
    end

    it "is comparable against Numeric inside a unit block" do
      unit("°F") do
        expect(ten_c == 50).to be true
        expect(ten_c != 50).to be false
        expect(ten_c == 10).to be false
        expect(ten_c != 10).to be true
        expect(ten_c > 49).to be true
        expect(ten_c < 51).to be true
      end

      unit("°C") do
        expect(ten_c == 10).to be true
        expect(ten_c > 9).to be true
        expect(ten_c < 9).to be false
        expect(ten_c < 11).to be true
        expect(ten_c > 11).to be false
      end
    end

    it "is not comparable against DecimalType" do
      expect { ten_c > DecimalType.new(3) }.to raise_exception(ArgumentError)
    end

    it "is comparable against DecimalType inside a unit block" do
      unit("°F") do
        expect(ten_c == DecimalType.new(50)).to be true
        expect(ten_c == DecimalType.new(10)).to be false
        expect(ten_c > DecimalType.new(49)).to be true
        expect(ten_c < DecimalType.new(49)).to be false
      end
    end
  end
end
