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

  describe "#planckian_cct", if: OpenHAB::Core.version >= OpenHAB::Core::V4_3 do
    it "returns a value for a pure 'white'" do
      warm_white = HSBType.from_cct(2700)
      expect(warm_white.planckian_cct.to_i).to be 2699
    end

    it "returns a value if in range (bare range)" do
      warm_white = HSBType.from_cct(2700)
      expect(warm_white.planckian_cct(range: 2000..6000).to_i).to be 2699
    end

    it "returns a value if in range (K range)" do
      warm_white = HSBType.from_cct(2700)
      expect(warm_white.planckian_cct(range: (2000 | "K")..(6000 | "K")).to_i).to be 2699
    end

    it "returns a value if in range (mired range)" do
      warm_white = HSBType.from_cct(2700)
      expect(warm_white.planckian_cct(range: (167 | "mired")..(500 | "mired")).to_i).to be 370
    end

    it "returns nil for red" do
      expect(HSBType::RED.planckian_cct).to be_nil
    end

    it "returns nil if the CCT is out of range (bare range)" do
      color = HSBType.from_cct(2000)
      expect(color.planckian_cct(range: 2700..6000)).to be_nil
    end

    it "returns nil if the CCT is out of range (K range)" do
      color = HSBType.from_cct(2000)
      expect(color.planckian_cct(range: (2700 | "K")..(6000 | "K"))).to be_nil
    end

    it "returns nil if the CCT is out of range (mired range)" do
      color = HSBType.from_cct(2000)
      expect(color.planckian_cct(range: (167 | "mired")..(370 | "mired"))).to be_nil
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
