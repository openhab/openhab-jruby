# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::HSBType do
  describe ".from_cct", if: OpenHAB::Core.version >= OpenHAB::Core::V4_3 do
    it "works with an integer" do
      warm_white = HSBType.from_cct(2700)
      expect(warm_white.hue.to_f).to be_within(0.01).of(38.51)
      expect(warm_white.saturation.to_f).to be_within(0.01).of(53.86)
      expect(warm_white.brightness).to eq 100
      # slight loss in the round-trip
      expect(warm_white.cct.to_i).to be 2699
    end

    it "works with a K quantity" do
      warm_white = HSBType.from_cct(2700 | "K")
      expect(warm_white.hue.to_f).to be_within(0.01).of(38.51)
      expect(warm_white.saturation.to_f).to be_within(0.01).of(53.86)
      expect(warm_white.brightness).to eq 100
      expect(warm_white.cct.to_i).to be 2699
    end

    it "works with a mired quantity" do
      warm_white = HSBType.from_cct(370 | "mired")
      expect(warm_white.hue.to_f).to be_within(0.01).of(38.51)
      expect(warm_white.saturation.to_f).to be_within(0.01).of(53.86)
      expect(warm_white.brightness).to eq 100
      expect(warm_white.cct.to_i).to be 2699
    end
  end

  it "is inspectable" do
    expect(HSBType.new.inspect).to eql "0 °,0%,0%"
  end

  it "can be constructed from a hex string" do
    expect(HSBType.new("#424D3D")).to eql HSBType.from_rgb(66, 77, 61)
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
