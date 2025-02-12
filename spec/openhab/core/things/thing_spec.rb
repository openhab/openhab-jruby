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

  describe "#provider" do
    it "works" do
      expect(thing.provider).to be OpenHAB::Core::Things::Provider.current
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

      it "supports lookup by channel UID" do
        channel_id = "phase#name"
        channel_uid = org.openhab.core.thing.ChannelUID.new(thing.uid, channel_id)
        expect(thing.channels[channel_uid]).not_to be_nil
        expect(thing.channels[channel_uid]).to be thing.channels[channel_id]
      end
    end
  end

  it "supports thing actions" do
    thing_actions = double
    allow(thing_actions).to receive(:elevation).and_return(300)
    allow($actions).to receive(:get).with("astro", "astro:sun:home").and_return(thing_actions)

    expect(thing.elevation).to be 300
  end

  describe "#bridge?" do
    it "returns false for non-bridges" do
      expect(thing).not_to be_bridge
    end

    it "returns true for bridges" do
      install_addon "binding-dscalarm", ready_markers: "openhab.xmlThingTypes"
      things.build { bridge "dscalarm:tcpserver:panel", "Alarm Panel" }

      expect(things["dscalarm:tcpserver:panel"]).to be_bridge
    end
  end

  describe "#properties" do
    it "works" do
      expect(thing.properties).to be_empty
    end

    it "supports setting properties" do
      logger.warn thing.properties.class
      thing.properties["test"] = "value"
      expect(thing.properties["test"]).to eq "value"
    end

    it "supports indifferent keys" do
      thing.properties["symbolic"] = "value"
      expect(thing.properties[:symbolic]).to eq "value"
    end
  end
end
