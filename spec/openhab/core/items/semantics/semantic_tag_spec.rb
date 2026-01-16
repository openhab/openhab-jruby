# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::Semantics::SemanticTag do
  it "is comparable" do
    expect(Semantics::Color).to be <= Semantics::Color
    expect(Semantics::Color).to eq Semantics::Color # rubocop:disable RSpec/IdenticalEqualityAssertion
    expect(Semantics::Color).not_to be < Semantics::Color
    expect(Semantics::HVAC).to be <= Semantics::Equipment
    expect(Semantics::ColorTemperature).not_to be < Semantics::Color
  end
end
