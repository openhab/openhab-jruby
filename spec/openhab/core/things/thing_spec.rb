# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Things::Thing do
  before do
    install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

    things.build do
      thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
    end
  end

  let(:thing) { things["astro:sun:home"] }

  describe "things" do
    it "provides access to all things" do
      expect(things.map { |t| t.uid.to_s }).to include("astro:sun:home")
    end

    it "supports [] lookup" do
      expect(things["astro:sun:home"].uid).to eq "astro:sun:home"
    end

    it "supports [] lookup using a ThingUID" do
      expect(things[org.openhab.core.thing.ThingUID.new("astro:sun:home")].uid).to eq "astro:sun:home"
    end
  end

  it "supports boolean thing status methods" do
    expect(thing).to be_online
    expect(thing).not_to be_uninitialized
    thing.disable
    expect(thing).not_to be_online
    expect(thing).to be_uninitialized
  end

  context "with channels" do
    before do
      items.build do
        string_item "PhaseName", channel: "astro:sun:home:phase#name"
      end
    end

    describe "#channels" do
      it "returns its linked item" do
        expect(thing.channels["phase#name"].item).to be PhaseName
      end

      it "returns its thing" do
        expect(thing.channels["phase#name"].thing).to be thing
      end
    end
  end

  it "supports thing actions" do
    thing_actions = double
    allow(thing_actions).to receive(:elevation).and_return(300)
    allow($actions).to receive(:get).with("astro", "astro:sun:home").and_return(thing_actions)

    expect(thing.elevation).to be 300
  end
end
