# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Things::Builder do
  before { install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes" }

  it "can create a thing" do
    things.build do
      thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
    end
    expect(home = things["astro:sun:home"]).not_to be_nil
    expect(home.channels["rise#event"]).not_to be_nil
    expect(home.configuration.get("geolocation")).to eq "0,0"
  end

  it "can create a thing with separate binding and type params" do
    things.build do
      thing "home", "Astro Sun Data", binding: "astro", type: "sun"
    end
    expect(things["astro:sun:home"]).not_to be_nil
  end

  it "can use symbols for config keys" do
    things.build do
      thing "astro:sun:home", "Astro Sun Data", config: { geolocation: "0,0" }
    end
    expect(home = things["astro:sun:home"]).not_to be_nil
    expect(home.configuration.get("geolocation")).to eq "0,0"
  end

  it "can create channels" do
    things.build do
      thing "astro:sun:home" do
        channel "channeltest", "string", config: { config1: "testconfig" }
      end
    end
    expect(home = things["astro:sun:home"]).not_to be_nil
    expect(home.channels.map { |c| c.uid.to_s }).to include("astro:sun:home:channeltest")
    channel = home.channels.find { |c| c.uid.id == "channeltest" }
    expect(channel.configuration.properties).to have_key("config1")
    expect(channel.configuration.get("config1")).to eq "testconfig"
  end
end
