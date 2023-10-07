# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Types::PointType do
  let(:point1) { PointType.new("30,20") }
  let(:point2) { PointType.new("40,20") }

  it "aliases `-` to `distance_from`" do
    expect((point1 - point2).to_i).to be 1_113_194
  end

  describe "#distance_from accepts supported types" do
    specify { expect(point1.distance_from(point2).to_i).to be 1_113_194 }
    specify { expect(point2.distance_from(point1).to_i).to be 1_113_194 }
  end

  describe "#latitude" do
    specify { expect(point1.latitude).to eq QuantityType.new("30 °") }
  end

  describe "#longitude" do
    specify { expect(point1.longitude).to eq QuantityType.new("20 °") }
  end

  describe "#altitude" do
    specify { expect(point1.altitude).to eq QuantityType.new("0 m") }
  end
end
