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

  describe "#formatted_state" do
    it "just returns the state if it has no format" do
      items.build { number_item MyTemp, state: 5.556 }
      expect(MyTemp.formatted_state[0...5]).to eql "5.556"
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

  describe "#thing" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
    end

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
    expect(all_items).to be_include(Switch1)
    expect(all_items).to be_include(Switch2)
    expect(all_items).to be_include(Switch3)

    expect([Switch1, Switch3]).not_to be_include(Switch2)
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
