# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::OnOffType do
  it "is inspectable" do
    expect(ON.inspect).to eql "ON"
  end

  it "responds to on? and off?" do
    expect(ON).to be_on
    expect(ON).not_to be_off
    expect(OFF).to be_off
    expect(OFF).not_to be_on
  end

  describe "case statements" do
    specify { expect(ON).to be === ON }
    specify { expect(ON).not_to be === OFF }
    specify { expect(OFF).to be === OFF }
    specify { expect(OFF).not_to be === ON }
    specify { expect(0..99).not_to be === ON }
    specify { expect(100).not_to be === ON }
    specify { expect(INCREASE).not_to be === OFF }
    specify { expect(DECREASE).not_to be === OFF }
    specify { expect(PercentType::ZERO).not_to be === OFF }
    specify { expect(1..100).not_to be === OFF }
    specify { expect(0..100).not_to be === ON }
  end

  it "supports the ! operator" do
    expect(!ON).to eql OFF
    expect(!OFF).to eql ON
  end

  describe "comparisons" do
    let(:fifty) { PercentType.new(50) }
    let(:zero) { PercentType::ZERO }

    specify { expect(fifty).not_to eq ON }
    specify { expect(zero).not_to eq OFF }
    specify { expect(fifty).not_to eq OFF }
    specify { expect(zero).not_to eq ON }
    specify { expect(ON).not_to eq fifty }
    specify { expect(ON).not_to eq zero }
    specify { expect(OFF).not_to eq zero }
    specify { expect(OFF).not_to eq fifty }

    specify { expect(ON).not_to eq NULL }
    specify { expect(ON).not_to eq UNDEF }
    specify { expect(ON).to eq ON }
    specify { expect(ON).not_to eq OFF }
    specify { expect(ON).not_to eq UP }
    specify { expect(ON).not_to eq REFRESH }

    specify { expect(OFF).not_to eq NULL }
    specify { expect(OFF).not_to eq UNDEF }
    specify { expect(OFF).not_to eq ON }
    specify { expect(OFF).to eq OFF }
    specify { expect(OFF).not_to eq UP }
    specify { expect(OFF).not_to eq REFRESH }

    specify { expect(ON != NULL).to be true }
    specify { expect(ON != UNDEF).to be true }
    specify { expect(ON != ON).to be false }
    specify { expect(ON != OFF).to be true }
    specify { expect(ON != UP).to be true }
    specify { expect(ON != REFRESH).to be true }

    specify { expect(OFF != NULL).to be true }
    specify { expect(OFF != UNDEF).to be true }
    specify { expect(OFF != ON).to be true }
    specify { expect(OFF != OFF).to be false }
    specify { expect(OFF != UP).to be true }
    specify { expect(OFF != REFRESH).to be true }
  end
end
