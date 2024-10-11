# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::NumberItem do
  subject(:item) { NumberOne }

  before do
    items.build do
      group_item "Numbers" do
        number_item "NumberOne", state: 0
        number_item "NumberTwo", state: 70, format: "%s"
        number_item "RangedNumber", range: 50..100
        number_item "UnittedRangedNumber", range: 2700..6000, unit: "K"
        number_item "OpenEndedNumber", range: 50.., unit: "°C"
      end
      number_item "NumberNull"
    end
  end

  it "is a number" do
    expect(item).to be_a_number_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  it "works with grep" do
    items.build { switch_item "Switch1" }
    expect(items.grep(NumberItem)).to match_array [NumberOne,
                                                   NumberTwo,
                                                   NumberNull,
                                                   RangedNumber,
                                                   UnittedRangedNumber,
                                                   OpenEndedNumber]
  end

  describe "#positive?" do
    specify { expect(NumberTwo).to be_positive }
    specify { expect(NumberNull).not_to be_positive }
  end

  it "respects unit block for commands" do
    items.build do
      number_item "Feet", unit: "ft"
    end

    unit("yd") do
      Feet << 2
    end
    expect(Feet.state).to eq(6 | "ft")
  end

  describe "#range?" do
    it "returns nil without a meaningful state description" do
      expect(NumberOne.range).to be_nil
      expect(NumberTwo.range).to be_nil
    end

    it "returns a value with a state description" do
      expect(RangedNumber.range).to eql 50..100
    end

    it "returns a QuantityType as necessary" do
      UnittedRangedNumber.update(3000 | "K")
      expect(UnittedRangedNumber.range).to eql((2700 | "K")..(6000 | "K"))
    end

    it "supports open ended ranges" do
      OpenEndedNumber.update(75 | "°C")
      expect(OpenEndedNumber.range).to eql((50 | "°C")..)
    end
  end
end
