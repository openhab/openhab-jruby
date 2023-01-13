# frozen_string_literal: true

RSpec.describe Numeric do
  describe "Unit conversion with |" do
    it "works" do
      qty = 1 | "kW"
      expect(qty).to eq QuantityType.new("1000 W")
      expect(qty.to_i).to eq 1
    end

    it "raises error on unknown unit" do
      expect { 1 | "foobarbaz" }.to raise_exception(ArgumentError)
    end

    it "falls back to the default behavior on non unit" do
      expect(1 | 2).to eq 3
    end
  end
end
