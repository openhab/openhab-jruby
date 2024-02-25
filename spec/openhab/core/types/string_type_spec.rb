# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::StringType do
  let(:state) { StringType.new("Hello") }

  it "is inspectable" do
    expect(StringType.new("my_string").inspect).to eql '"my_string"'
  end

  it "converts to a string" do
    expect(StringType.new("my_string").to_s).to eql "my_string"
  end

  it "can be used in a case with a regex" do
    result = case StringType.new("hi")
             when /hi/ then true
             else false
             end
    expect(result).to be true
  end

  it "can use =~ operator" do
    expect(StringType.new("hi") =~ /[a-z]+/).to be 0
  end

  it "supports string operations" do
    expect(state + " World!").to eql "Hello World!" # rubocop:disable Style/StringConcatenation
  end

  it "acts as a string for other string operations" do
    expect("Hello " + state).to eql "Hello Hello" # rubocop:disable Style/StringConcatenation
  end

  it "works with grep and a regex" do
    strings = [state]
    expect(strings.grep(/^H/)).to eql [state]
  end

  describe "comparisons" do
    let(:state2) { StringType.new("World") }

    specify { expect(state == "Hello").to be true }
    specify { expect(state == "World").to be false }
    specify { expect(state != "Hello").to be false }
    specify { expect(state != "World").to be true }
    specify { expect(state == state2).to be false }
    specify { expect(state != state2).to be true }
    specify { expect(state == nil).to be false } # rubocop:disable Style/NilComparison
    specify { expect(state != nil).to be true } # rubocop:disable Style/NonNilCheck
  end

  describe "#eql?" do
    it "works" do
      expect(state).to eql StringType.new("Hello")
    end

    it "returns false when compared against a plain string" do
      expect(state).not_to eql "Hello"
    end
  end
end
