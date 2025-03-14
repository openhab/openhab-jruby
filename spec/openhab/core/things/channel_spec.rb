# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Things::Channel do
  context "with linked channels" do
    subject(:channel) { things["astro:sun:home"].channels["phase#name"] }

    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      end
    end

    describe "#item" do
      it "returns nil for an unlinked item" do
        expect(channel.item).to be_nil
      end

      it "returns its linked item" do
        channel = self.channel
        items.build do
          string_item PhaseName, channel:
        end

        expect(channel.item).to eql PhaseName
        expect(channel.item_name).to eql "PhaseName"
      end

      it "returns all linked items" do
        channel = self.channel
        items.build do
          string_item(PhaseName1, channel:)
          string_item PhaseName2, channel:
        end

        expect(channel.items).to match_array [PhaseName1, PhaseName2]
        expect(channel.item_names).to match_array %w[PhaseName1 PhaseName2]
      end
    end

    describe "#link (noun)" do
      it "returns nil for an unlinked item" do
        expect(channel.link).to be_nil
      end

      it "returns the link" do
        channel = self.channel
        items.build do
          string_item PhaseName, channel:
        end

        expect(channel.link).not_to be_nil
        expect(channel.link.item).to eql PhaseName
      end
    end

    describe "#links" do
      it "returns an empty array for an unlinked item" do
        expect(channel.links).to be_empty
      end

      it "returns its linked channels" do
        channel = self.channel
        items.build do
          string_item(PhaseName1, channel:)
          string_item PhaseName2, channel:
        end
        expect(channel.links.map(&:item)).to match_array [PhaseName1, PhaseName2]
      end

      it "can clear all links" do
        channel = self.channel
        items.build do
          string_item PhaseName, channel:
        end

        channel.links.clear
        expect(channel.links).to be_empty
        expect(channel.item).to be_nil
      end
    end

    describe "#link (verb)" do
      subject(:channel) { things["astro:sun:home"].channels["position#azimuth"] }

      it "accepts an item name (String) argument" do
        items.build { string_item SunAzimuth }
        channel.link("SunAzimuth")
        expect(channel.links.map(&:item_name)).to match_array ["SunAzimuth"]
      end

      it "accepts an Item argument" do
        items.build { string_item SunAzimuth }
        channel.link(SunAzimuth)
        expect(channel.links.map(&:item_name)).to match_array ["SunAzimuth"]
      end

      it "accepts a configuration for the link" do
        items.build { string_item "SunAzimuth" }
        channel.link(SunAzimuth, profile: "offset", offset: "30")
        expect(channel.links.map(&:item_name)).to match_array ["SunAzimuth"]
        expect(channel.link.configuration).to eq({ "profile" => "offset", "offset" => "30" })
      end

      it "can replace an existing link" do
        items.build { string_item "SunAzimuth" }
        channel.link(SunAzimuth)
        channel.link(SunAzimuth, profile: "offset", offset: "30")
        expect(channel.links.map(&:item_name)).to match_array ["SunAzimuth"]
        expect(channel.link.configuration).to eq({ "profile" => "offset", "offset" => "30" })
      end
    end

    describe "#unlink" do
      it "works" do
        items.build { string_item "PhaseName" }
        channel.link(PhaseName)
        channel.unlink(PhaseName)
        expect(channel.links).to be_empty
      end
    end
  end
end
