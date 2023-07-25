# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Items::Builder do
  %i[color contact date_time dimmer group image location number player rollershutter string switch].each do |type|
    it "can create a #{type} item" do
      items.build { send(:"#{type}_item", "MyItem", "My Label") }
      expect(MyItem.label).to eql "My Label"
      expect(MyItem).to be_a(Object.const_get(:"#{type.to_s.gsub(/(^[a-z]|_[a-z])/) do |x|
                                                    x.delete("_").capitalize
                                                  end }Item"))
    end
  end

  it "complains if you try to add an item that already exists" do
    items.build { switch_item "Switch1" }
    expect { items.build { switch_item "Switch1" } }.to raise_error(ArgumentError)
  end

  it "can remove an item" do
    items.build { switch_item "MySwitchItem", autoupdate: false, channel: "binding:type:thing:channel" }
    items.remove(MySwitchItem)
    expect(items["MySwitchItem"]).to be_nil
    # make sure metadata and channel links also got cleaned up
    expect(OpenHAB::Core::Items::Metadata::Provider.instance.all).to be_empty
    expect(OpenHAB::Core::Things::Links::Provider.instance.all).to be_empty
  end

  it "can create items in a group" do
    items.build do
      group_item "Group1"
      group_item "MyGroupItem" do
        switch_item "MySwitchItem"
        switch_item "MySwitch2", groups: [Group1]
      end
    end

    expect(MyGroupItem.members.to_a).to match_array [MySwitchItem, MySwitch2]
    expect(MySwitchItem.groups).to eq [MyGroupItem]
    expect(MySwitch2.groups).to match_array [Group1, MyGroupItem]
  end

  it "can add items to groups" do
    items.build do
      group_item "MyGroupItem"
      group_item "Group2"
      switch_item "MySwitchItem", group: MyGroupItem
      switch_item "MySwitchItem2", groups: [Group2]
      switch_item "MySwitchItem3", group: "MyGroupItem", groups: [Group2]
    end

    expect(MyGroupItem.members.to_a).to match_array [MySwitchItem, MySwitchItem3]
    expect(MySwitchItem.groups).to eql [MyGroupItem]
    expect(MySwitchItem2.groups).to eql [Group2]
    expect(MySwitchItem3.groups).to match_array [MyGroupItem, Group2]
  end

  it "can set a dimension on a number item" do
    items.build do
      number_item "MyNumberItem", dimension: "Power"
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
  end

  it "can set a unit on a number item" do
    items.build do
      number_item "MyNumberItem", dimension: "Power", unit: "kW"
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem.metadata["unit"].value).to eql "kW"
    expect(MyNumberItem.unit.to_s).to eql "kW"
  end

  it "can infer the dimension from the explicit unit for a number item" do
    items.build do
      number_item "MyNumberItem", unit: "kW"
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem.metadata["unit"].value).to eql "kW"
    expect(MyNumberItem.unit.to_s).to eql "kW"
    expect(MyNumberItem.state_description.pattern).to eql "%s %unit%"
  end

  it "can format a number item" do
    items.build do
      number_item "MyNumberItem", format: "something %d else"
    end

    MyNumberItem.update(1)
    expect(MyNumberItem.state_description.pattern).to eql "something %d else"
  end

  it "does not overwrite an explicit format with the unit" do
    items.build do
      number_item "MyNumberItem", format: "something %d else", unit: "W"
    end

    MyNumberItem.update(1)
    expect(MyNumberItem.unit.to_s).to eql "W"
    expect(MyNumberItem.state_description.pattern).to eql "something %d else"
  end

  it "can set an icon" do
    items.build do
      switch_item "MySwitch", icon: :light
    end

    expect(MySwitch.category).to eql "light"
  end

  it "can add tags" do
    items.build do
      switch_item "MySwitch", tags: ["MyTag", Semantics::Switch]
      switch_item "MySwitch2", tag: "MyTag"
      switch_item "MySwitch3", tag: "MyTag", tags: ["MyTag2"]
      switch_item "MySwitch4", tags: "MyTag"
    end

    expect(MySwitch.tags).to match_array %w[MyTag Switch]
    expect(MySwitch2.tags).to match_array ["MyTag"]
    expect(MySwitch3.tags).to match_array %w[MyTag MyTag2]
    expect(MySwitch4.tags).to match_array ["MyTag"]
  end

  it "raises errors on invalid argument types" do
    rspec = self
    items.build do
      rspec.expect { switch_item "Switch1", tags: [1] }.to rspec.raise_error(ArgumentError)
      rspec.expect { switch_item "Switch1", tag: 2 }.to rspec.raise_error(ArgumentError)
      switch_item "SwitchNone"
      rspec.expect { switch_item "Switch1", group: SwitchNone }.to rspec.raise_error(ArgumentError)
      rspec.expect { switch_item "Switch1", groups: SwitchNone }.to rspec.raise_error(ArgumentError)
      rspec.expect { switch_item "Switch1", group: [SwitchNone] }.to rspec.raise_error(ArgumentError)
    end
  end

  it "can configure autoupdate" do
    items.build do
      switch_item "MySwitch1", autoupdate: true
      switch_item "MySwitch2", autoupdate: false
      switch_item "MySwitch3"
    end

    expect(MySwitch1.metadata["autoupdate"]&.value).to eq "true"
    expect(MySwitch2.metadata["autoupdate"]&.value).to eq "false"
    expect(MySwitch3.metadata["autoupdate"]).to be_nil
  end

  it "can configure expires" do
    items.build do
      switch_item "MySwitch1", expire: 1.hour
      switch_item "MySwitch2", expire: "2h"
      switch_item "MySwitch3", expire: [3.hours, OFF]
      switch_item "MySwitch4", expire: ["4h", { command: OFF }]
      string_item "MyString", expire: [5.hours, "EXPIRED"]
    end

    expect(MySwitch1.metadata["expire"]&.value).to eq "1h"
    expect(MySwitch2.metadata["expire"]&.value).to eq "2h"
    expect(MySwitch3.metadata["expire"]&.value).to eq "3h,state=OFF"
    expect(MySwitch4.metadata["expire"]&.value).to eq "4h,command=OFF"
    expect(MyString.metadata["expire"]&.value).to eq "5h,state='EXPIRED'"
  end

  it "passes homekit helper on to metadata" do
    items.build do
      switch_item "MySwitch1", homekit: ["Switchable", { somethingElse: "more" }]
    end

    expect(MySwitch1.metadata["homekit"]&.value).to eql "Switchable"
    expect(MySwitch1.metadata["homekit"].to_h).to eql({ "somethingElse" => "more" })
  end

  it "prefixes group members" do
    items.build do
      group_item "MyGroup" do
        self.name_base = "Family"
        self.label_base = "Family Room "

        switch_item "Lights_Switch", "Lights"
        switch_item "Lamps_Switch", "Lamps"
      end
    end

    expect(FamilyLights_Switch.label).to eql "Family Room Lights"
    expect(FamilyLamps_Switch.label).to eql "Family Room Lamps"
  end

  it "can create a group with a base type" do
    items.build do
      group_item "MyGroup", type: :switch
    end

    expect(MyGroup.base_item).to be_a(SwitchItem)
  end

  it "can create a group with a function and base type" do
    items.build do
      group_item "MyGroup", type: :switch, function: "OR(ON,OFF)"
    end

    expect(MyGroup.base_item).to be_a(SwitchItem)
    expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Or)
    expect(MyGroup.function.parameters.to_a).to eql [ON, OFF]
  end

  it "sets initial state" do
    items.build { number_item "Number1", state: 1 }

    expect(Number1.state).to eq 1
  end

  it "sets initial state on a switch with false" do
    items.build { switch_item "Switch1", state: false }
    expect(Switch1.state).to be OFF
  end

  it "sets initial state on a dimmer with an integer" do
    items.build { dimmer_item "Dimmer1", state: 50 }
    expect(Dimmer1.state).to eq 50
  end

  it "sets initial state on a date time item with a string" do
    items.build { date_time_item "DateTimeItem1", state: "1970-01-01T00:00:00+00:00" }
    expect(DateTimeItem1.state).to eq Time.parse("1970-01-01T00:00:00+00:00")
  end

  describe "entity lookup" do
    it "can reference a group item directly" do
      items.build do
        group_item "group1"
        group_item "group2", group: group1
      end
      expect(group2.groups).to eql [group1]
    end

    it "can reference a group item within another group_item" do
      items.build do
        group_item "group1"
        group_item "group2" do
          switch_item "switch1", group: group1
        end
      end
      expect(switch1.groups).to match_array([group1, group2])
    end

    it "can reference an item (constant) that doesn't exist yet" do
      items.build do
        switch_item Switch1
      end
      expect(Switch1).to be_a(SwitchItem)
    end

    it "can reference an item (method) that doesn't exist yet" do
      items.build do
        group_item gMyGroup
      end
      expect(gMyGroup).to be_a(GroupItem)
    end

    it "can reference an item (constant) that doesn't exist yet inside a group" do
      items.build do
        group_item "gMyGroup" do
          switch_item Switch1
        end
      end
      expect(Switch1).to be_a(SwitchItem)
    end

    it "can reference an item (method) that doesn't exist yet inside a group" do
      items.build do
        group_item "gMyGroup" do
          group_item gGroup2
        end
      end
      expect(gGroup2).to be_a(GroupItem)
    end
  end

  context "with a thing" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"
      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      end
    end

    it "can link an item to a channel" do
      items.build { string_item "StringItem1", channel: "astro:sun:home:season#name" }
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "can link to an item channel with a profile" do
      items.build do
        date_time_item "LastUpdated", channel: ["astro:sun:home:season#name", { profile: "system:timestamp-update" }]
      end
      expect(LastUpdated.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing (string) for channels" do
      items.build do
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", channel: "season#name"
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing for channels" do
      items.build do
        group_item "MyGroup", thing: things["astro:sun:home"] do
          string_item "StringItem1", channel: "season#name"
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing (string) for channels with multiple groups" do
      items.build do
        group_item "OtherGroup"
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", channel: "season#name", group: OtherGroup
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing (string) for channels with a latent added group" do
      items.build do
        group_item "OtherGroup"
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", channel: "season#name" do
            group "OtherGroup"
          end
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end
  end
end
