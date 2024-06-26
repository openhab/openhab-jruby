# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::StringListType do
  let(:state) { StringListType.new(%w[a b]) }

  it "is inspectable" do
    expect(state.inspect).to eql '#<OpenHAB::Core::Types::StringListType ["a", "b"]>'
  end

  it "converts to an array" do
    expect(state.to_a).to eql %w[a b]
  end

  it "supports array operations" do
    expect(state.first).to eql "a"
    expect(state.last).to eql "b"
    expect(state.size).to be 2
  end

  describe "comparisons" do
    let(:state2) { StringListType.new(%w[a b]) }

    specify { expect(state == %w[a b]).to be true }
    specify { expect(state == %w[a c]).to be false }
    specify { expect(state != %w[a b]).to be false }
    specify { expect(state != %w[a c]).to be true }
    specify { expect(state == state2).to be true }
    specify { expect(state != state2).to be false }
  end

  describe "#eql?" do
    it "works" do
      expect(state).to eql StringListType.new(%w[a b])
    end

    it "returns false when compared against a plain array" do
      expect(state).not_to eql %w[a b]
    end
  end
end
