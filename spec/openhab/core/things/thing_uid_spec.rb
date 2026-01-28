# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Things::ThingUID do
  subject(:uid) { described_class.new("astro:sun:home") }

  describe "#inspect" do
    it "logs the full UID" do
      expect(uid.inspect).to eql "astro:sun:home"
    end
  end

  describe "#==" do
    it "works against a regular string" do
      expect(uid).to eq "astro:sun:home"
    end

    it "works with a string LHS (via ThingUID#to_str)" do
      expect("astro:sun:home").to eq uid # rubocop:disable RSpec/ExpectActual
    end
  end

  describe "useful string interrogations work" do
    # rubocop:disable Performance/StringInclude
    it "supports them" do
      expect(uid.start_with?("astro:")).to be true
      expect(uid.end_with?(":home")).to be true
      expect(uid.include?("sun")).to be true
      expect(uid.length).to be 14
      expect(uid.match?(/astro:sun/)).to be true
      expect(uid =~ /astro:sun/).to be 0
      expect(uid.match(/astro:sun/)).not_to be_nil

      expect(uid.start_with?("binding:")).to be false
      expect(uid.end_with?(":away")).to be false
      expect(uid.include?("moon")).to be false
      expect(uid.match?(/binding:sun/)).to be false
      expect(uid =~ /binding:sun/).to be_nil
      expect(uid.match(/binding:sun/)).to be_nil
    end
    # rubocop:enable Performance/StringInclude
  end

  describe "#binding_id" do
    it "returns the correct value" do
      expect(uid.binding_id).to eql "astro"
    end
  end
end
