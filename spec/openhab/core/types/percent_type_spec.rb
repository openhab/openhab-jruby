# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::PercentType do
  let(:state) { PercentType.new(50) }

  it "is inspectable" do
    expect(PercentType.new(10).inspect).to eql "10%"
  end

  it "responds to on?, off?, up?, and down?" do
    state = PercentType.new(0)
    expect(state).to be_up
    expect(state).not_to be_down
    expect(state).not_to be_on
    expect(state).to be_off
    state = PercentType.new(50)
    expect(state).not_to be_up
    expect(state).not_to be_down
    expect(state).to be_on
    expect(state).not_to be_off
    state = PercentType.new(100)
    expect(state).not_to be_up
    expect(state).to be_down
    expect(state).to be_on
    expect(state).not_to be_off
  end

  it "can scale" do
    expect(PercentType.new(0).scale(0..255)).to be 0
    expect(PercentType.new(100).scale(0..255)).to be 255
    expect(PercentType.new(100).scale(0...256)).to be 255
    expect(PercentType.new(0).scale(25..75)).to be 25
    expect(PercentType.new(50).scale(25..75)).to be 50
    expect(PercentType.new(100).scale(25..75)).to be 75
    expect(PercentType.new(50).scale(-50..10.0)).to be(-20.0)
    expect(PercentType.new(100).scale(-50..10.0)).to be 10.0
  end

  it "handles #to_byte" do
    expect(PercentType.new(50).to_byte).to be 128
  end

  describe "case statements" do
    specify { expect(OFF).not_to be === PercentType::ZERO }
    specify { expect(ON).not_to be === PercentType::ZERO }
    specify { expect(DECREASE).not_to be === PercentType::ZERO }
    specify { expect(STOP).not_to be === PercentType::ZERO }
    specify { expect(MOVE).not_to be === PercentType::ZERO }
    specify { expect(UP).not_to be === PercentType::ZERO }
    specify { expect(DOWN).not_to be === PercentType::ZERO }
    specify { expect(0).to be === PercentType::ZERO }
    specify { expect(0..50).to be === PercentType::ZERO }
    specify { expect(ON).not_to be === PercentType.new(50) }
    specify { expect(INCREASE).not_to be === PercentType.new(50) }
    specify { expect(50).to be === PercentType.new(50) }
    specify { expect(ON).not_to be === PercentType::HUNDRED }
    specify { expect(STOP).not_to be === PercentType::HUNDRED }
    specify { expect(MOVE).not_to be === PercentType::HUNDRED }
    specify { expect(UP).not_to be === PercentType::HUNDRED }
    specify { expect(DOWN).not_to be === PercentType::HUNDRED }
    specify { expect(0..99).not_to be === PercentType::HUNDRED }
    specify { expect(100).to be === PercentType::HUNDRED }
  end

  describe "comparison to number" do
    specify { expect(state > 50).to be false }
    specify { expect(state == 50).to be true }
    specify { expect(state < 60).to be true }
    specify { expect(state == PercentType.new(50)).to be true }
  end

  describe "math operations" do
    specify { expect(state + 20).to eq 70 }
    specify { expect(state - 20).to eq 30 }
    specify { expect(state * 2).to eq 100 }
    specify { expect(state / 2).to eq 25 }
    specify { expect(20 + state).to eq 70 }
    specify { expect(90 - state).to eq 40 }
    specify { expect(2 * state).to eq 100 }
    specify { expect(100 / state).to eq 2 }
    specify { expect(70 % state).to eq 20 }
  end

  describe "ranges" do
    specify { expect(0...50).not_to be === PercentType.new(55) }
    specify { expect(50..100).to be === PercentType.new(55) }
  end

  describe "comparisons" do
    let(:ten) { PercentType.new(10) }
    let(:number_ten) { DecimalType.new(10) }
    let(:number_five) { DecimalType.new(5) }
    let(:number_twenty) { DecimalType.new(20) }

    # PercentType vs PercentType
    specify { expect(ten).to eql ten }
    specify { expect(ten).to eq ten }
    specify { expect(ten).not_to eq PercentType.new(1) }
    specify { expect(ten != PercentType.new(1)).to be true }
    specify { expect(ten != ten).to be false }
    specify { expect(ten).to be < PercentType.new(10.1) }
    specify { expect(ten).not_to be < PercentType.new(5) }
    specify { expect(ten).to be > PercentType.new(5) }
    specify { expect(ten).not_to be > PercentType.new(10.1) }

    # PercentType vs DecimalType
    specify { expect(ten).not_to eql number_ten }
    specify { expect(ten).to eq number_ten }
    specify { expect(ten != number_five).to be true }
    specify { expect(ten != number_ten).to be false }

    specify { expect(ten).to be < number_twenty }
    specify { expect(ten).not_to be < number_five }
    specify { expect(ten).to be > number_five }
    specify { expect(ten).not_to be > number_twenty }

    # PercentType vs Numeric
    specify { expect(ten).not_to eql 10 }
    specify { expect(ten).to eq 10 }
    specify { expect(ten).not_to eq 10.1 }
    specify { expect(ten != 2).to be true }
    specify { expect(ten != 10).to be false }

    specify { expect(ten).to be < 20 }
    specify { expect(ten).not_to be < 5 }
    specify { expect(ten).to be > 5 }
    specify { expect(ten).not_to be > 20 }

    # PercentType vs OnOffType
    specify { expect(ten).not_to eql ON }
    specify { expect(ten).not_to eq ON }
    specify { expect(ten).not_to eq OFF }
    specify { expect(ten != ON).to be true }
    specify { expect(ten != OFF).to be true }

    # Numeric vs PercentType
    specify { expect(10).not_to eql ten }
    specify { expect(10).to eq ten }
    specify { expect(10.1).not_to eq ten }
    specify { expect(2 != ten).to be true }
    specify { expect(10 != ten).to be false }

    specify { expect(5).to be < ten }
    specify { expect(20).not_to be < ten }
    specify { expect(11).to be > ten }
    specify { expect(5).not_to be > ten }
  end
end
