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
          channels = org_config.delete(:channels)
          thing(org_config.delete(:uid) || default_uid, org_config.delete(:label), **org_config) do
            channels&.each do |c|
              c = c.dup
              channel(c.delete(:uid), c.delete(:type), **c)
            end
          end
        end
        # Unwrap the thing object now before creating the new thing.
        # See the comment in items/builder_spec.rb for more details.
        org_thing = org_thing.__getobj__
        yield :original, org_thing if block

        new_thing = things.build do
          channels = new_config.delete(:channels)
          thing(new_config.delete(:uid) || default_uid, new_config.delete(:label), **new_config) do
            channels&.each do |c|
              c = c.dup
              channel(c.delete(:uid), c.delete(:type), **c)
            end
          end
        end
        new_thing = new_thing.__getobj__
        yield :updated, new_thing if block

        case thing_to_keep
        when :new_thing then expect(new_thing).not_to be org_thing
        when :old_thing then expect(new_thing).to be org_thing
        end

        [org_thing, new_thing]
      end

      it "keeps the original thing when there are no changes" do
        config = {
          uid: "a:b:c",
          label: "Label",
          bridge: "a:b:bridge",
          config: { ipAddress: "1" },
          channels: [{ uid: "a", type: "string", config: { stateTopic: "a/b/c" } }]
        }.freeze
        build_and_update(config, config, thing_to_keep: :old_thing)
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

  context "with channels" do
    it "works" do
      things.build do
        thing "astro:sun:home" do
          channel "channeltest", "string"
        end
      end
      expect(home = things["astro:sun:home"]).not_to be_nil
      expect(home.channels["channeltest"].uid.to_s).to eql "astro:sun:home:channeltest"
    end

    context "with channel attributes" do
      it "supports config" do
        thing = things.build do
          thing "astro:sun:home" do
            channel "channeltest", "string", config: { config1: "testconfig" }
          end
        end
        channel = thing.channels["channeltest"]
        expect(channel.configuration).to have_key("config1")
        expect(channel.configuration.get("config1")).to eq "testconfig"
      end

      context "with default_tags" do
        it "accepts a string tag" do
          thing = things.build do
            thing "astro:sun:home" do
              channel "channeltest", "string", default_tags: "tag1"
            end
          end
          expect(thing.channels["channeltest"].default_tags.to_a).to eq %w[tag1]
        end

        it "accepts a symbolic tag" do
          thing = things.build do
            thing "astro:sun:home" do
              channel "channeltest", "string", default_tags: :tag1
            end
          end
          expect(thing.channels["channeltest"].default_tags.to_a).to eq %w[tag1]
        end

        it "accepts a Semantic tag constant" do
          thing = things.build do
            thing "astro:sun:home" do
              channel "channeltest", "string", default_tags: Semantics::Status
            end
          end
          expect(thing.channels["channeltest"].default_tags.to_a).to eq %w[Status]
        end

        it "accepts an array of symbolic tag" do
          thing = things.build do
            thing "astro:sun:home" do
              channel "channeltest", "string", default_tags: %i[tag1]
            end
          end
          expect(thing.channels["channeltest"].default_tags.to_a).to eq %w[tag1]
        end

        it "accepts an array of string tag" do
          thing = things.build do
            thing "astro:sun:home" do
              channel "channeltest", "string", default_tags: %w[tag1]
            end
          end
          expect(thing.channels["channeltest"].default_tags.to_a).to eq %w[tag1]
        end

        it "accepts an array of Semantic tag constants" do
          thing = things.build do
            thing "astro:sun:home" do
              channel "channeltest", "string", default_tags: [Semantics::Status]
            end
          end
          expect(thing.channels["channeltest"].default_tags.to_a).to eq %w[Status]
        end
      end

      context "with auto_update_policy" do
        it "accepts symbolic policy" do
          thing = things.build do
            thing "astro:sun:home" do
              org.openhab.core.thing.type.AutoUpdatePolicy.values.each do |policy| # rubocop:disable Style/HashEachMethods
                channel policy.to_s.downcase, "string", auto_update_policy: policy.to_s.downcase.to_sym
              end
            end
          end

          org.openhab.core.thing.type.AutoUpdatePolicy.values.each do |policy| # rubocop:disable Style/HashEachMethods
            expect(thing.channels[policy.to_s.downcase].auto_update_policy).to eq policy
          end
        end

        it "accepts AutoUpdatePolicy enum" do
          thing = things.build do
            thing "astro:sun:home" do
              org.openhab.core.thing.type.AutoUpdatePolicy.values.each do |policy| # rubocop:disable Style/HashEachMethods
                channel policy.to_s.downcase, "string", auto_update_policy: policy
              end
            end
          end

          org.openhab.core.thing.type.AutoUpdatePolicy.values.each do |policy| # rubocop:disable Style/HashEachMethods
            expect(thing.channels[policy.to_s.downcase].auto_update_policy).to eq policy
          end
        end
      end

      it "supports label, description, properties, and accepted_item_type attributes" do
        thing = things.build do
          thing "astro:sun:home" do
            channel "channeltest",
                    "string",
                    "testlabel",
                    description: "testdescription",
                    properties: { property1: "testproperty" },
                    accepted_item_type: "Number"
          end
        end
        channel = thing.channels["channeltest"]
        expect(channel.label).to eq "testlabel"
        expect(channel.description).to eq "testdescription"
        expect(channel.properties).to eq("property1" => "testproperty")
        expect(channel.accepted_item_type).to eq "Number"
      end

      it "infers accepted_item_type from ChannelTypeRegistry" do
        thing = things.build do
          thing "astro:sun:home" do
            channel "test", "start"
          end
        end
        channel = thing.channels["test"]
        expect(channel.accepted_item_type).to eq "DateTime"
      end

      it "can customize predefined channels" do
        thing = things.build do
          thing "astro:sun:home" do
            channel "rise#start", "start", config: { offset: 5 }
          end
        end
        channel = thing.channels["rise#start"]
        expect(channel.configuration[:offset].to_i).to eq 5
      end
    end
  end

  describe "#bridge" do
    before { install_addon "binding-dscalarm", ready_markers: "openhab.xmlThingTypes" }

    it "can create a bridge" do
      things.build do
        bridge "dscalarm:tcpserver:panel", config: { ipAddress: "127.0.0.1" }
      end
    end

    it "can create nested things" do
      things.build do
        bridge "dscalarm:tcpserver:panel", config: { ipAddress: "127.0.0.1" } do
          thing "dscalarm:zone:front_door", config: { zoneNumber: 1 }
        end
      end

      expect(things["dscalarm:zone:front_door"].bridge_uid).to eq "dscalarm:tcpserver:panel"
    end
  end
end
