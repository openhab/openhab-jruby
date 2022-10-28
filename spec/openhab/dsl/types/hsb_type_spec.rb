# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Types::HSBType do
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

  describe "conversion to hashes and arrays" do
    let(:state) { HSBType::RED }

    specify do
      expect(state.to_h).to eql({
                                  hue: 0 | "°",
                                  saturation: PercentType::HUNDRED,
                                  brightness: PercentType::HUNDRED
                                })
    end

    specify do
      expect(state.to_h(:hsb)).to eql({
                                        hue: 0 | "°",
                                        saturation: PercentType::HUNDRED,
                                        brightness: PercentType::HUNDRED
                                      })
    end

    specify { expect(state.to_h(:rgb)).to eql({ red: 255, green: 0, blue: 0 }) }
    specify { expect(state.to_a).to eql [0 | "°", PercentType::HUNDRED, PercentType::HUNDRED] }
    specify { expect(state.to_a(:hsb)).to eql [0 | "°", PercentType::HUNDRED, PercentType::HUNDRED] }
    specify { expect(state.to_a(:rgb)).to eql [255, 0, 0] }
  end
end