# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::Source do
  subject(:source) { described_class.new(source_string) }

  let(:source_string) { +"org.openhab.bundle1$actor1=>org.openhab.bundle2$actor2" }

  describe ".new" do
    it "accepts a string source" do
      expect(source.components).to be_frozen
      expect(source.components.size).to be 2
      expect(source.components[0].bundle).to eql "org.openhab.bundle1"
      expect(source.components[0].actor).to eql "actor1"
      expect(source.components[1].bundle).to eql "org.openhab.bundle2"
      expect(source.components[1].actor).to eql "actor2"
      expect(source.source).to eql source_string
      expect(source.source).to be_frozen
      expect(source.source).not_to be source_string
    end

    it "accepts an array of components" do
      components = [
        OpenHAB::Core::Events::Source::Component.build("org.openhab.bundle1", "actor1"),
        OpenHAB::Core::Events::Source::Component.build("org.openhab.bundle2", "actor2")
      ]
      source = described_class.new(components)
      expect(source.components).to eql components
      expect(source.components).to be_frozen
      expect(source.components).not_to be components
      expect(source.source).to eql source_string
    end
  end

  it "behaves like a string" do
    expect(source).to eq source_string
    expect(source).not_to eq "garbage"
    expect(source).to be < "z"
    expect { source < 1 }.to raise_error ArgumentError
    expect(source_string).to eq source
    expect(source).not_to eql source_string
    expect(source_string).not_to eql source
    expect(source.split("=>")).to eql source_string.split("=>")
    expect(source.length).to be source_string.length
    expect(source.inspect).to eql source_string
  end

  describe "#delegate" do
    it "adds a component to the delegation chain" do
      new_source = source.delegate("org.openhab.bundle3", "actor3")
      expect(new_source).to be_a described_class
      expect(new_source.components.size).to be 3
      expect(new_source.components[0]).to eql source.components[0]
      expect(new_source.components[1]).to eql source.components[1]
      expect(new_source.components[2].bundle).to eql "org.openhab.bundle3"
      expect(new_source.components[2].actor).to eql "actor3"
      expect(new_source).to eq(
        "org.openhab.bundle1$actor1=>org.openhab.bundle2$actor2=>org.openhab.bundle3$actor3"
      )
    end
  end

  describe "#sender?" do
    it "checks by bundle or actor" do
      expect(source.sender?("org.openhab.bundle1")).to be true
      expect(source.sender?("actor1")).to be true
      expect(source.sender?("org.openhab.bundle2")).to be true
      expect(source.sender?("actor2")).to be true
      expect(source.sender?("org.openhab.bundle3")).to be false
      expect(source.sender?("actor3")).to be false
    end

    it "checks by bundle only" do
      expect(source.sender?(bundle: "org.openhab.bundle1")).to be true
      expect(source.sender?(bundle: "actor1")).to be false
      expect(source.sender?(bundle: "org.openhab.bundle2")).to be true
      expect(source.sender?(bundle: "actor2")).to be false
      expect(source.sender?(bundle: "org.openhab.bundle3")).to be false
    end

    it "checks by actor only" do
      expect(source.sender?(actor: "org.openhab.bundle1")).to be false
      expect(source.sender?(actor: "actor1")).to be true
      expect(source.sender?(actor: "org.openhab.bundle2")).to be false
      expect(source.sender?(actor: "actor2")).to be true
      expect(source.sender?(actor: "actor3")).to be false
    end

    it "allows regexes" do
      expect(source.sender?(/bundle1/)).to be true
      expect(source.sender?(/bundle3/)).to be false
    end
  end

  describe "actor_for" do
    it "returns the actor for the specified bundle" do
      expect(source.actor_for("org.openhab.bundle1")).to eql "actor1"
      expect(source.actor_for("org.openhab.bundle2")).to eql "actor2"
      expect(source.actor_for("org.openhab.bundle3")).to be_nil
    end
  end

  describe "#reject" do
    it "returns a new Source without the rejected components" do
      new_source = source.reject("org.openhab.bundle1")
      expect(new_source).to be_a described_class
      expect(new_source).to eq "org.openhab.bundle2$actor2"

      new_source = source.reject("org.openhab.bundle2")
      expect(new_source).to be_a described_class
      expect(new_source).to eq "org.openhab.bundle1$actor1"

      new_source = source.reject("org.openhab.bundle3")
      expect(new_source).to be_a described_class
      expect(new_source).to eq source
    end

    it "accepts a block" do
      new_source = source.reject { |component| component.bundle == "org.openhab.bundle1" }
      expect(new_source).to be_a described_class
      expect(new_source).to eq "org.openhab.bundle2$actor2"
    end
  end
end
