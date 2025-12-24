# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::Source::Component do
  describe ".parse" do
    it "parses a component string" do
      component = described_class.parse("org.openhab.bundle$actor")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to eql "actor"
    end

    it "parses a component string without actor" do
      component = described_class.parse("org.openhab.bundle")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to be_nil
    end

    it "parses an actor with $ in it" do
      component = described_class.parse("org.openhab.bundle$actor$with$dollars")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to eql "actor$with$dollars"
    end
  end

  describe ".build" do
    it "builds a component from bundle and actor" do
      component = described_class.build("org.openhab.bundle", "actor")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to eql "actor"
    end

    it "builds a component without actor" do
      component = described_class.build("org.openhab.bundle")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to be_nil
    end

    it "escapes => in the actor", if: OpenHAB::Core.version >= OpenHAB::Core::V5_1 do
      component = described_class.build("org.openhab.bundle", "actor=>with=>arrows")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to eql "actor__with__arrows"
    end

    it "escapes __ in the actor", if: OpenHAB::Core.version >= OpenHAB::Core::V5_1 do
      component = described_class.build("org.openhab.bundle", "actor__with__underscores")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to eql "actor____with____underscores"
    end

    it "disallows special characters", if: OpenHAB::Core.version >= OpenHAB::Core::V5_1 do
      expect do
        described_class.build("org.openhab.bundle1=>org.openhab.bundle2")
      end.to raise_error(ArgumentError)
      expect do
        described_class.build("org.openhab.bundle$actor")
      end.to raise_error(ArgumentError)
    end

    it "allows $ in the actor" do
      component = described_class.build("org.openhab.bundle", "actor$with$dollars")
      expect(component.bundle).to eql "org.openhab.bundle"
      expect(component.actor).to eql "actor$with$dollars"
    end
  end

  describe "#to_s" do
    it "serializes with $" do
      expect(described_class.build("org.openhab.bundle", "actor").to_s).to eql "org.openhab.bundle$actor"
    end
  end

  describe "#==" do
    subject(:component) { described_class.parse(component_string) }

    let(:component_string) { "org.openhab.bundle$actor" }

    it "compares with another Source" do
      component2 = described_class.parse(component_string)
      expect(component).to eq component2
      expect(component).to eql component2

      component3 = described_class.parse("org.openhab.bundle$other_actor")
      expect(component).not_to eq component3
      expect(component).not_to eql component3
    end

    it "compares with a string" do
      expect(component).to eq component_string
      expect(component).not_to eq "org.openhab.bundle3$actor3"
      expect(component).not_to eql component_string

      expect(component_string).to eq component
      expect("org.openhab.bundle3$actor3").not_to eq component # rubocop:disable RSpec/ExpectActual
      expect(component_string).not_to eql component
    end

    it "returns false when comparing with other types" do
      expect(component).not_to eq 42
      expect(component).not_to eq :symbol
    end
  end
end
