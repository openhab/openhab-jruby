# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::TimeSeries do
  let(:ts) do
    described_class.new(:add).tap do |ts|
      ts.add(Instant.of_epoch_second(1), DecimalType.new(1))
      ts.add(Instant.of_epoch_second(2), DecimalType.new(2))
    end
  end

  it "is inspectable" do
    expect(described_class.new(:add).inspect).to eql "#<OpenHAB::Core::Types::TimeSeries policy=ADD " \
                                                     "begin=+1000000000-12-31T23:59:59.999999999Z " \
                                                     "end=-1000000000-01-01T00:00:00Z size=0>"
  end

  it "is accessible without using a fully qualified name" do
    TimeSeries.new
  end

  it "supports specifying the policy as a symbol" do
    expect(TimeSeries.new(:add).policy).to be TimeSeries::Policy::ADD
    expect(TimeSeries.new(:add)).to be_add
    expect(TimeSeries.new(:replace).policy).to be TimeSeries::Policy::REPLACE
    expect(TimeSeries.new(:replace)).to be_replace
  end

  it "defaults to replace policy" do
    expect(TimeSeries.new).to be_replace
  end

  describe "#add?" do
    it "works" do
      expect(ts.add?).to be true
    end
  end

  describe "#replace?" do
    it "works" do
      expect(ts.replace?).to be false
    end
  end

  describe "#add" do
    it "accepts a Ruby time as instant" do
      ts.add(Time.at(0), DecimalType.new(1))
      expect(ts.begin).to eql Instant.of_epoch_second(0)
    end

    it "accepts a string value" do
      ts.add(Time.at(0), "1")
      expect(ts.first.state).to eql StringType.new("1")
    end

    it "accepts a numeric value" do
      ts.add(Time.at(0), 1)
      expect(ts.first.state).to eql DecimalType.new(1)
    end

    it "accepts a QuantityType" do
      ts.add(Time.at(0), 1 | "W")
      expect(ts.first.state.class).to be QuantityType
    end

    it "raises an error if the value is not a State, number or string" do
      expect { ts.add(Time.at(0), Object.new) }.to raise_error ArgumentError
    end
  end

  describe "#<<" do
    it "works" do
      ts << [Time.at(3), 3]
      expect(ts.size).to be 3
      expect(ts.first.state).to eql DecimalType.new(1)
      expect(ts.begin).to eql Instant.of_epoch_second(1)
      expect(ts.last.state).to eql DecimalType.new(3)
      expect(ts.end).to eql Instant.of_epoch_second(3)
    end
  end

  context "when accessed as an Array" do
    it "is frozen" do
      expect(ts.states).to be_frozen
      expect { ts.unshift }.to raise_error FrozenError
    end

    it "supports #to_a" do
      expect(ts.to_a).to all(be_a TimeSeries::Entry)
    end

    it "supports #[]" do
      expect(ts[0].timestamp).to eql Instant.of_epoch_second(1)
      expect(ts[0].state).to eql DecimalType.new(1)
    end

    it "supports #first" do
      expect(ts.first.timestamp).to eql Instant.of_epoch_second(1)
      expect(ts.first.state).to eql DecimalType.new(1)
    end

    it "supports #last" do
      expect(ts.last.timestamp).to eql Instant.of_epoch_second(2)
      expect(ts.last.state).to eql DecimalType.new(2)
    end

    it "can be mapped to its states" do
      expect(ts.map(&:state)).to eql [DecimalType.new(1), DecimalType.new(2)]
      expect(ts.sum(&:state)).to eql DecimalType.new(3)
    end

    it "supports #each" do
      sum = DecimalType.new(0)
      ts.each { |entry| sum += entry.state }
      expect(sum).to eql DecimalType.new(3)
    end
  end
end
