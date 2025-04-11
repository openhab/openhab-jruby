# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::Item do
  before do
    items.build do
      group_item "House" do
        switch_item "LightSwitch", group: "NonExistent", tags: "Switch"
      end
    end
  end

  describe "#groups" do
    it "doesn't include non-existent groups" do
      expect(LightSwitch.groups.map(&:name)).to eql ["House"]
    end
  end

  describe "#all_groups" do
    it "includes all ancestor groups" do
      items.build do
        group_item "MainFloor", groups: [House] do
          switch_item LightSwitch2
        end
      end

      expect(LightSwitch2.all_groups).to eql [MainFloor, House]
    end

    it "doesn't get tripped up by cyclical groups" do
      items.build do
        group_item gGroup1, group: "gGroup2"
        group_item gGroup2, group: gGroup1 do
          switch_item LightSwitch2
        end
      end

      expect(gGroup1.groups).to eql [gGroup2]
      expect(gGroup2.groups).to eql [gGroup1]
      expect(LightSwitch2.all_groups).to eql [gGroup2, gGroup1]
    end
  end

  describe "#group_names" do
    it "works" do
      expect(LightSwitch.group_names.to_a).to match_array %w[House NonExistent]
    end
  end

  describe "#member_of?" do
    it "accepts strings" do
      expect(LightSwitch).to be_member_of("House")
    end

    it "accepts group items" do
      expect(LightSwitch).to be_member_of(House)
    end

    it "ignores other types" do
      expect(LightSwitch).not_to be_member_of(LightSwitch)
    end

    it "returns false" do
      expect(LightSwitch).not_to be_member_of("House2")
    end
  end

  describe "#tags" do
    it "works" do
      expect(LightSwitch.tags).to match_array %w[Switch]
    end

    it "can be set" do
      LightSwitch.tags = "Control", "Switch"
      expect(LightSwitch.tags).to match_array %w[Control Switch]
    end

    it "can be set to an array" do
      LightSwitch.tags = %w[foo baz]
      expect(LightSwitch.tags).to match_array %w[foo baz]
    end

    it "can be set using symbols" do
      LightSwitch.tags = :Control, :Test
      expect(LightSwitch.tags).to match_array %w[Control Test]
    end

    it "can be set with Semantics::Tag" do
      LightSwitch.tags = Semantics::Control, Semantics::Light
      expect(LightSwitch.tags).to match_array %w[Control Light]
    end

    it "can remove all tags with an empty array" do
      LightSwitch.tags = []
      expect(LightSwitch.tags).to be_empty
    end

    it "can remove all tags with nil" do
      LightSwitch.tags = nil
      expect(LightSwitch.tags).to be_empty
    end
  end

  describe "#tagged?" do
    it "works" do
      expect(LightSwitch).to be_tagged("Switch")
      expect(LightSwitch).not_to be_tagged("Setpoint")
    end

    it "works with semantic classes" do
      expect(LightSwitch).to be_tagged(Semantics::Switch)
    end
  end

  describe "#to_s" do
    it "uses the label" do
      items.build { switch_item "LightSwitch2", "My Light Switch" }
      expect(LightSwitch2.to_s).to eql "My Light Switch"
    end

    it "use the item's name if it doesn't have a label" do
      expect(LightSwitch.to_s).to eql "LightSwitch"
    end
  end

  describe "#command" do
    it "works" do
      LightSwitch.on
      expect(LightSwitch).to be_on
    end

    it "returns `self` (wrapped in a proxy)" do
      expect(LightSwitch.on).to be LightSwitch
    end

    it "accepts a source" do
      items.build { switch_item LightSwitch2 }
      source = nil
      rule do
        received_command LightSwitch2
        run do |event|
          source = event.source
        end
      end
      LightSwitch2.command(ON, source: "one")
      expect(source).to eql "one"
      # command aliases work
      LightSwitch2.on(source: "two")
      expect(source).to eql "two"
      LightSwitch2.refresh(source: "three")
      expect(source).to eql "three"
    end
  end

  describe "#update" do
    it "works" do
      LightSwitch.update(ON)
      expect(LightSwitch).to be_on
    end

    it "returns `self` (wrapped in a proxy)" do
      expect(LightSwitch.update(ON)).to be LightSwitch
    end

    it "interprets `nil` as `NULL`" do
      LightSwitch.on
      LightSwitch.update(nil)
      expect(LightSwitch).to be_null
    end
  end

  describe "#undef?" do
    it "works" do
      LightSwitch.update(UNDEF)
      expect(LightSwitch).to be_undef
      LightSwitch.on
      expect(LightSwitch).not_to be_undef
    end
  end

  describe "#null?" do
    it "works" do
      LightSwitch.update(NULL)
      expect(LightSwitch).to be_null
      LightSwitch.on
      expect(LightSwitch).not_to be_null
    end
  end

  describe "#state?" do
    it "works" do
      LightSwitch.update(NULL)
      expect(LightSwitch).not_to be_state
      expect(LightSwitch.state).to be_nil
      LightSwitch.update(UNDEF)
      expect(LightSwitch).not_to be_state
      expect(LightSwitch.state).to be_nil
      LightSwitch.on
      expect(LightSwitch).to be_state
      expect(LightSwitch.state).not_to be_nil
    end
  end

  describe "#was", if: OpenHAB::Core.version >= OpenHAB::Core::V5_0 do
    it "returns nil if the item had never changed" do
      expect(LightSwitch.was).to be_nil
    end

    it "returns the previous state" do
      LightSwitch.update(ON)
      LightSwitch.update(OFF)
      expect(LightSwitch.was).to eql ON
      expect(LightSwitch.was).to be_on
      LightSwitch.update(ON)
      expect(LightSwitch.was).to eql OFF
      expect(LightSwitch.was).to be_off
    end

    it "returns nil if the item was NULL or UNDEF" do
      LightSwitch.update(UNDEF)
      LightSwitch.update(ON)
      expect(LightSwitch.was).to be_nil
      LightSwitch.update(NULL)
      LightSwitch.update(ON)
      expect(LightSwitch.was).to be_nil
    end
  end

  describe "#was?", if: OpenHAB::Core.version >= OpenHAB::Core::V5_0 do
    it "works" do
      expect(LightSwitch.was?).to be false
      LightSwitch.update(NULL)
      expect(LightSwitch.was?).to be false
      LightSwitch.update(ON)
      expect(LightSwitch.was?).to be false
      LightSwitch.update(UNDEF)
      expect(LightSwitch.was?).to be true
      LightSwitch.update(OFF)
      expect(LightSwitch.was?).to be false
      LightSwitch.update(ON)
      expect(LightSwitch.was?).to be true
    end
  end

  context "with was_*? predicates", if: OpenHAB::Core.version >= OpenHAB::Core::V5_0 do
    describe "#was_undef?" do
      it "works" do
        LightSwitch.update(UNDEF)
        LightSwitch.update(ON)
        expect(LightSwitch.was_undef?).to be true
        LightSwitch.update(OFF)
        expect(LightSwitch.was_undef?).to be false
      end
    end

    describe "#was_null?" do
      it "works" do
        LightSwitch.update(NULL)
        LightSwitch.update(ON)
        expect(LightSwitch.was_null?).to be true
        LightSwitch.update(OFF)
        expect(LightSwitch.was_null?).to be false
      end
    end

    describe "#was_on?" do
      it "works" do
        LightSwitch.update(ON)
        LightSwitch.update(OFF)
        expect(LightSwitch.was_on?).to be true
        LightSwitch.update(ON)
        expect(LightSwitch.was_on?).to be false
      end
    end

    describe "#was_off?" do
      it "works" do
        LightSwitch.update(OFF)
        LightSwitch.update(ON)
        expect(LightSwitch.was_off?).to be true
        LightSwitch.update(OFF)
        expect(LightSwitch.was_off?).to be false
      end
    end

    describe "#was_up?" do
      it "works" do
        items.build { rollershutter_item Shutter, state: UP }
        Shutter.update(DOWN)
        expect(Shutter.was_up?).to be true
        Shutter.update(UP)
        expect(Shutter.was_up?).to be false
      end
    end

    describe "#was_down?" do
      it "works" do
        items.build { rollershutter_item Shutter, state: DOWN }
        Shutter.update(UP)
        expect(Shutter.was_down?).to be true
        Shutter.update(DOWN)
        expect(Shutter.was_down?).to be false
      end
    end

    describe "#was_open?" do
      it "works" do
        items.build { contact_item Door, state: OPEN }
        Door.update(CLOSED)
        expect(Door.was_open?).to be true
        Door.update(OPEN)
        expect(Door.was_open?).to be false
      end
    end

    describe "#was_closed?" do
      it "works" do
        items.build { contact_item Door, state: CLOSED }
        Door.update(OPEN)
        expect(Door.was_closed?).to be true
        Door.update(CLOSED)
        expect(Door.was_closed?).to be false
      end
    end

    describe "#was_playing?" do
      it "works" do
        items.build { player_item Player, state: PLAY }
        Player.update(PAUSE)
        expect(Player.was_playing?).to be true
        Player.update(PLAY)
        expect(Player.was_playing?).to be false
      end
    end

    describe "#was_paused?" do
      it "works" do
        items.build { player_item Player, state: PAUSE }
        Player.update(PLAY)
        expect(Player.was_paused?).to be true
        Player.update(PAUSE)
        expect(Player.was_paused?).to be false
      end
    end

    describe "#was_rewinding?" do
      it "works" do
        items.build { player_item Player, state: REWIND }
        Player.update(PLAY)
        expect(Player.was_rewinding?).to be true
        Player.update(REWIND)
        expect(Player.was_rewinding?).to be false
      end
    end

    describe "#was_fast_forwarding?" do
      it "works" do
        items.build { player_item Player, state: FASTFORWARD }
        Player.update(PLAY)
        expect(Player.was_fast_forwarding?).to be true
        Player.update(FASTFORWARD)
        expect(Player.was_fast_forwarding?).to be false
      end
    end
  end

  describe "#formatted_state" do
    it "just returns the state if it has no format" do
      items.build { number_item MyTemp, state: 5.556 }
      if OpenHAB::Core.version < OpenHAB::Core::V4_2
        expect(MyTemp.formatted_state[0...5]).to eql "5.556"
      else
        # This is due to the change in OH4.2
        # https://github.com/openhab/openhab-core/pull/4175
        expect(MyTemp.formatted_state).to eql "6"
      end
    end

    it "handles format strings" do
      items.build { number_item MyTemp, format: "I have %.1f bananas", state: 5.556 }
      expect(MyTemp.formatted_state).to eql "I have 5.6 bananas"
    end

    it "returns NULL when the state is NULL" do
      items.build { number_item MyTemp, format: "%.1f custom unit" }
      expect(MyTemp.formatted_state).to eq "NULL"
    end

    it "returns UNDEF when the state is UNDEF" do
      items.build { number_item MyTemp, format: "%.1f custom unit", state: UNDEF }
      expect(MyTemp.formatted_state).to eq "UNDEF"
    end

    it "formats quantity types" do
      items.build { number_item MyTemp, format: "%.1f °F", state: 32.1234 }
      expect(MyTemp.formatted_state).to eq "32.1 °F"
    end

    it "does unit transformations if necessary" do
      items.build { number_item MyTemp, format: "%.1f °F", unit: "°C", state: 1.234 }
      expect(MyTemp.formatted_state).to eq "34.2 °F"
    end
  end

  context "with linked channels" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
    end

    describe "#thing" do
      it "returns nil for an unlinked item" do
        expect(LightSwitch.thing).to be_nil
      end

      it "returns its linked thing" do
        items.build do
          string_item "PhaseName", channel: "astro:sun:home:phase#name"
        end

        expect(PhaseName.thing).to be things["astro:sun:home"]
      end

      it "returns all linked things" do
        items.build do
          string_item "PhaseName" do
            channel "astro:sun:home:phase#name"
            channel "astro:moon:home:phase#name"
          end
        end

        expect(PhaseName.things).to match_array [things["astro:sun:home"], things["astro:moon:home"]]
      end
    end

    describe "#channel" do
      it "returns nil for an unlinked item" do
        expect(LightSwitch.channel_uid).to be_nil
        expect(LightSwitch.channel).to be_nil
      end

      it "returns its linked channel" do
        items.build do
          string_item "PhaseName", channel: "astro:sun:home:phase#name"
        end

        expect(PhaseName.channel).to be things["astro:sun:home"].channels["phase#name"]
        expect(PhaseName.channel_uid).to eq things["astro:sun:home"].channels["phase#name"].uid
      end

      it "returns all linked channels" do
        items.build do
          string_item "PhaseName" do
            channel "astro:sun:home:phase#name"
            channel "astro:moon:home:phase#name"
          end
        end

        expect(PhaseName.channels).to match_array [things["astro:sun:home"].channels["phase#name"],
                                                   things["astro:moon:home"].channels["phase#name"]]
        expect(PhaseName.channel_uids).to match_array [things["astro:sun:home"].channels["phase#name"].uid,
                                                       things["astro:moon:home"].channels["phase#name"].uid]
      end
    end

    describe "#link (noun)" do
      it "returns nil for an unlinked item" do
        expect(LightSwitch.link).to be_nil
      end

      it "returns the link" do
        items.build do
          string_item "PhaseName", channel: "astro:sun:home:phase#name"
        end

        expect(PhaseName.link).not_to be_nil
        expect(PhaseName.link.channel).to be things["astro:sun:home"].channels["phase#name"]
      end
    end

    describe "#links" do
      it "returns an empty array for an unlinked item" do
        items.build { string_item "UnlinkedItem" }
        expect(UnlinkedItem.links).to be_empty
      end

      it "returns its linked channels" do
        items.build do
          number_item "SunAzimuth" do
            channel "astro:sun:home:position#azimuth", profile: "offset", offset: "30"
          end
        end
        expect(SunAzimuth.links.map(&:channel_uid)).to match_array ["astro:sun:home:position#azimuth"]
        expect(SunAzimuth.links.first.configuration).to eq({ "profile" => "offset", "offset" => "30" })
      end

      it "can clear all links" do
        items.build do
          number_item "SunAzimuth", channel: "astro:sun:home:position#azimuth"
        end
        SunAzimuth.links.clear
        expect(SunAzimuth.links).to be_empty
        expect(SunAzimuth.thing).to be_nil
      end
    end

    describe "#link (verb)" do
      it "accepts a channel uid (String) argument" do
        items.build { string_item "SunAzimuth" }
        SunAzimuth.link("astro:sun:home:position#azimuth")
        expect(SunAzimuth.links.map(&:channel_uid)).to match_array ["astro:sun:home:position#azimuth"]
      end

      it "accepts a ChannelUID argument" do
        items.build { string_item "SunAzimuth" }
        SunAzimuth.link(OpenHAB::Core::Things::ChannelUID.new("astro:sun:home:position#azimuth"))
        expect(SunAzimuth.links.map(&:channel_uid)).to match_array ["astro:sun:home:position#azimuth"]
      end

      it "accepts a Channel argument" do
        items.build { string_item "SunAzimuth" }
        SunAzimuth.link(things["astro:sun:home"].channels["position#azimuth"])
        expect(SunAzimuth.links.map(&:channel_uid)).to match_array ["astro:sun:home:position#azimuth"]
      end

      it "accepts a configuration for the link" do
        items.build { string_item "SunAzimuth" }
        SunAzimuth.link("astro:sun:home:position#azimuth", profile: "offset", offset: "30")
        expect(SunAzimuth.links.map(&:channel_uid)).to match_array ["astro:sun:home:position#azimuth"]
        expect(SunAzimuth.links.first.configuration).to eq({ "profile" => "offset", "offset" => "30" })
      end

      it "can replace an existing link" do
        items.build { string_item "SunAzimuth" }
        SunAzimuth.link("astro:sun:home:position#azimuth")
        SunAzimuth.link("astro:sun:home:position#azimuth", profile: "offset", offset: "30")
        expect(SunAzimuth.links.map(&:channel_uid)).to match_array ["astro:sun:home:position#azimuth"]
        expect(SunAzimuth.links.first.configuration).to eq({ "profile" => "offset", "offset" => "30" })
      end
    end

    describe "#unlink" do
      it "works" do
        items.build { string_item "SunAzimuth" }
        channel = "astro:sun:home:position#azimuth"
        SunAzimuth.link(channel)
        SunAzimuth.unlink(channel)
        expect(SunAzimuth.links).to be_empty
      end
    end
  end

  # See https://github.com/boc-tothefuture/openhab-jruby/issues/252
  it "can be used as a hash key" do
    hash = {
      LightSwitch => "hi"
    }
    expect(hash[LightSwitch]).to eql "hi"
    expect(hash).to have_key(LightSwitch)
    expect(hash).not_to have_key(House)
  end

  it "works with hash value" do
    hash = {
      a: LightSwitch
    }
    expect(hash).to have_value(LightSwitch)
    expect(hash).not_to have_value(House)
  end

  it "can be used in an array" do
    items.build do
      switch_item "Switch1", state: OFF
      switch_item "Switch2", state: OFF
      switch_item "Switch3", state: ON
    end

    all_items = [Switch1, Switch2, Switch3]
    expect(all_items).to include(Switch1)
    expect(all_items).to include(Switch2)
    expect(all_items).to include(Switch3)

    expect([Switch1, Switch3]).not_to include(Switch2)
  end

  it "compares items by item, not by state" do
    items.build do
      switch_item "Switch1", state: OFF
      switch_item "Switch2", state: OFF
      switch_item "Switch3", state: ON
    end

    expect(Switch1).not_to eq Switch2
    expect(Switch1).not_to eq Switch3
  end

  describe "#label=" do
    it "calls update on the provider" do
      expect(LightSwitch.provider).to receive(:update)
      LightSwitch.label = "Light Switch"
    end

    it "doesn't call update if no change was made" do
      LightSwitch.label = "Light Switch"
      expect(LightSwitch.provider).not_to receive(:update)
      LightSwitch.label = "Light Switch"
    end

    it "raises an error if the item's provider doesn't support update" do
      expect(LightSwitch.provider).not_to receive(:update)
      allow(LightSwitch).to receive(:provider).and_return(Object.new)
      expect { LightSwitch.label = "Light Switch" }.to raise_error(FrozenError)
    end

    it "ignores provider check if the item doesn't yet have a provider" do
      expect(LightSwitch.provider).not_to receive(:update)
      allow(LightSwitch).to receive(:provider).and_return(nil)
      LightSwitch.label = "Light Switch"
      expect(LightSwitch.label).to eql "Light Switch"
    end
  end

  describe "#modify" do
    it "batches multiple provider update calls" do
      expect(LightSwitch.provider).to receive(:update).once
      LightSwitch.modify do
        LightSwitch.label = "Light Switch 1"
        LightSwitch.label = "Light Switch 2"
      end
    end

    it "doesn't call update if the item's provider doesn't support it and we're forced" do
      expect(LightSwitch.provider).not_to receive(:update)
      allow(LightSwitch).to receive(:provider).and_return(nil)
      LightSwitch.modify(force: true) do
        LightSwitch.label = "Light Switch"
      end
    end

    it "passes self to the block" do
      LightSwitch.modify do |item|
        expect(item).to be LightSwitch
        item.modify do |item2|
          expect(item2).to be LightSwitch
        end
      end
    end
  end

  describe "entity lookup" do
    it "doesn't confuse a method call with an item" do
      items.build { group_item "gGroup" }

      expect(gGroup).to be_a(GroupItem)
      expect { gGroup(:argument) }.to raise_error(NoMethodError)
      expect do
        gGroup do
          nil
        end
      end.to raise_error(NoMethodError)
    end
  end
end
