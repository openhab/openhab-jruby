# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::NumberItem do
  subject(:item) { NumberOne }

  before do
    items.build do
      group_item "Numbers" do
        number_item "NumberOne", state: 0
        number_item "NumberTwo", state: 70
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
    expect(items.grep(NumberItem)).to match_array [NumberOne, NumberTwo, NumberNull]
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
end
