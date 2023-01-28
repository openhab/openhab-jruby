# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::HSBType do
  it "is inspectable" do
    expect(HSBType.new.inspect).to eql "0 °,0%,0%"
  end

  it "can be constructed from a hex string" do
    expect(HSBType.new("#abcdef").to_hex).to eql "#aacbed"
  end

  it "responds to on? and off?" do
    expect(HSBType::BLACK).not_to be_on
    expect(HSBType::BLACK).to be_off
    expect(HSBType::WHITE).to be_on
    expect(HSBType::WHITE).not_to be_off
    expect(HSBType::RED).to be_on
    expect(HSBType::RED).not_to be_off
    expect(HSBType.new(0, 0, 5)).to be_on
    expect(HSBType.new(0, 0, 5)).not_to be_off
  end

  describe "case statements" do
    specify { expect(HSBType.new("0,0,0")).to be === HSBType.new("0,0,0") }
    specify { expect(HSBType.new("1,2,3")).not_to be === HSBType.new("0,0,0") }
    specify { expect(ON).not_to be === HSBType.new("0,0,0") }
    specify { expect(OFF).not_to be === HSBType.new("0,0,0") }
    specify { expect(DECREASE).not_to be === HSBType.new("0,0,0") }
    specify { expect(INCREASE).not_to be === HSBType.new("0,0,0") }
  end

  describe "comparisons" do
    specify { expect(HSBType::RED).to eq HSBType::RED }
    specify { expect(HSBType::RED != HSBType::RED).to be false }
    specify { expect(HSBType::RED).to eq 100 }
    specify { expect(HSBType::RED).not_to eq ON }
    specify { expect(HSBType::RED).not_to eq HSBType.new(1, 100, 100) }
    specify { expect(HSBType::RED).not_to eq HSBType.new(0, 99, 100) }
    specify { expect(HSBType::RED).not_to eq HSBType.new(0, 100, 99) }
  end
end
