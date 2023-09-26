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
    expect(home).to be_enabled
  end

  context "when things already exist and build is called" do
    context "with update: false argument" do
      it "complains if you try to create a thing with the same UID" do
        uid = "a:b:c"
        things.build { thing uid, "old label" }
        expect { things.build(update: false) { thing uid, "new label" } }.to raise_error(ArgumentError)
      end

      it "fails creating the new thing but doesn't cause any changes in the original thing" do
        uid = "a:b:c"
        old_channel = nil
        properties = {
          bridge: "a:b:bridge_a",
          location: "location_a",
          config: { identity: "config_a" },
          enabled: true
        }.freeze
        old_thing = things.build do
          thing uid, "old label", **properties do
            old_channel = channel "x", "string"
          end
        end

        expect(things[uid].enabled?).to eql properties[:enabled]

        expect do
          things.build(update: false) do
            thing uid,
                  "new label",
                  bridge: "a:b:bridge_b",
                  location: "location_b",
                  config: { identity: "config_b" },
                  enabled: !properties[:enabled] do
              channel "y", "number"
            end
          end
        end.to raise_error(ArgumentError)
        thing = things[uid]
        expect(thing.label).to eql "old label"
        expect(thing.__getobj__).to be old_thing.__getobj__
        expect(thing.bridge_uid).to eq properties[:bridge]
        expect(thing.location).to eq properties[:location]
        expect(thing.configuration).to eq properties[:config]
        expect(thing.enabled?).to eql properties[:enabled]
        expect(thing.channels).to match_array(old_channel)
      end
    end

    context "with default arguments (update: true)" do
      subject(:thing) { things[uid] }

      let(:uid) { "a:b:c" }

      it "refuses to update an existing thing from a different provider" do
        uid = "a:b:file-thing"
        existing_thing = OpenHAB::DSL::Things::ThingBuilder.new(uid).build
        allow(OpenHAB::DSL.things).to receive(:key?).with(uid).and_return(true)
        allow(OpenHAB::DSL.things).to receive(:[]).with(uid).and_return(existing_thing)
        expect { things.build { thing uid } }.to raise_error(FrozenError)
      end

      it "can create a new thing" do
        things.build do
          thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
        end
        expect(home = things["astro:sun:home"]).not_to be_nil
        expect(home.channels["rise#event"]).not_to be_nil
        expect(home.configuration.get("geolocation")).to eq "0,0"
      end

      # @return [Array<OpenHAB::Core::Things::Thing, OpenHAB::Core::Things::Thing>]
      #   An array of unproxied things [original, updated]
      def build_and_update(org_config, new_config, thing_to_keep: :new_thing, &block)
        org_config = org_config.dup
        new_config = new_config.dup
        default_uid = uid
        org_thing = things.build do
          thing(org_config.delete(:uid) || default_uid, org_config.delete(:label), **org_config)
        end
        # Unwrap the thing object now before creating the new thing.
        # See the comment in items/builder_spec.rb for more details.
        org_thing = org_thing.__getobj__
        yield :original, org_thing if block

        new_thing = things.build do
          thing(new_config.delete(:uid) || default_uid, new_config.delete(:label), **new_config)
        end
        new_thing = new_thing.__getobj__
        yield :updated, new_thing if block

        case thing_to_keep
        when :new_thing then expect(new_thing).not_to be org_thing
        when :old_thing then expect(new_thing).to be org_thing
        end

        [org_thing, new_thing]
      end

      context "with changes" do
        it "replaces the old thing when the label is different" do
          build_and_update({ label: "Old Label" }, { label: "New Label" })
          expect(thing.label).to eql "New Label"
        end

        it "replaces the old thing when the bridge is different" do
          build_and_update({ bridge: "a:b:bridge_a" }, { bridge: "a:b:bridge_b" })
          expect(thing.bridge_uid).to eq "a:b:bridge_b"
        end

        it "replaces the old thing when the location is different" do
          build_and_update({ location: "location a" }, {})
          expect(thing.location).to be_nil
        end

        it "replaces the old thing when the config is different" do
          build_and_update({ config: { ipAddress: "1" } }, { config: { ipAddress: "2" } })
          expect(thing.configuration[:ipAddress]).to eq "2"
        end

        it "keeps the old thing when nothing is different" do
          build_and_update({}, {}, thing_to_keep: :old_thing)
        end

        it "keeps the old thing but update the state" do
          build_and_update({}, { enabled: false }, thing_to_keep: :old_thing)
          expect(thing).not_to be_enabled
        end
      end
    end
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
