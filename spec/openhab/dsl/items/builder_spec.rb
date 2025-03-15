# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Items::Builder do
  %i[call color contact date_time dimmer group image location number player rollershutter string switch].each do |type|
    it "can create a #{type} item" do
      items.build { send(:"#{type}_item", "MyItem", "My Label") }
      expect(MyItem.label).to eql "My Label"
      expect(MyItem).to be_a(Object.const_get(:"#{type.to_s.gsub(/(^[a-z]|_[a-z])/) do |x|
                                                    x.delete("_").capitalize
                                                  end }Item"))
    end
  end

  context "when items already exist and build is called" do
    context "with update: false" do
      it "raises an error" do
        items.build { switch_item "Switch1" }
        expect { items.build(update: false) { switch_item "Switch1" } }.to raise_error(ArgumentError)
      end

      it "the failure in creating the new item doesn't cause any changes to the original item" do
        things.build do
          thing "a:b:c" do
            channel "old", "switch"
            channel "new", "switch"
          end
        end

        properties = {
          tags: ["Light"],
          unit: "W",
          format: "%f",
          ga: ["Light", {}],
          groups: ["Group1"],
          icon: "light",
          autoupdate: "true",
          expire: "1h",
          channel: "a:b:c:old",
          state: 1
        }.freeze

        items.build { number_item "Number1", "Old Label", **properties }

        expect do
          items.build(update: false) do
            number_item "Number1",
                        "New Label",
                        tags: "Measurement",
                        unit: "°C",
                        format: "%s",
                        ga: "Fan",
                        groups: "Group2",
                        icon: "window",
                        autoupdate: "false",
                        expire: ["2h", { ignore_state_updates: true }],
                        channel: "a:b:c:new",
                        state: 2
          end
        end.to raise_error(ArgumentError)
        expect(Number1.label).to eql "Old Label"
        expect(Number1.tags.to_a).to eql properties[:tags]
        expect(Number1.unit.to_s).to eql properties[:unit]
        expect(Number1.state_description.pattern).to eql properties[:format]
        expect(Number1.metadata[:ga]).to eq properties[:ga]
        expect(Number1.group_names.to_a).to eql properties[:groups]
        expect(Number1.category).to eql properties[:icon]
        expect(Number1.metadata[:autoupdate].value).to eql properties[:autoupdate]
        expect(Number1.metadata[:expire].value).to eq properties[:expire]
        expect(Number1.metadata[:expire]).to be_empty
        expect(Number1.links.first.linked_uid.to_s).to eql properties[:channel]
        expect(Number1.links.size).to be 1
        expect(Number1.state.to_i).to eql properties[:state]
      end
    end

    context "with the default argument (update: true)" do
      subject(:item) { Built }

      it "raises an error if the existing item is from a different provider" do
        item_name = "ItemFromAnotherProvider"
        existing_item = OpenHAB::Core::Items::StringItem.new(item_name)
        generic_item_provider = OpenHAB::OSGi.service("org.openhab.core.items.ItemProvider")
        allow(OpenHAB::DSL.items).to receive(:key?).with(item_name).and_return(true)
        allow(OpenHAB::DSL.items).to receive(:[]).with(item_name).and_return(existing_item)
        allow(existing_item).to receive(:provider).and_return(generic_item_provider)
        expect { items.build { number_item item_name } }.to raise_error(FrozenError)
      end

      #
      # Create an item, then create it again with build(update: true)
      #
      # @param [Hash] org_config Config to create the original item
      # @param [Hash] new_config Config to create the new item
      # @param [true,false] update_expected Whether the provider should update the item with the new config
      # @return [Array<OpenHAB::Core::Items::Item, OpenHAB::Core::Items::Item>]
      #   An array of [original item, updated item]. These are unproxied raw items
      #
      def build_and_update(org_config, new_config, update_expected: true, &block)
        org_config = org_config.dup
        new_config = new_config.dup
        org_item = items.build do
          send("#{org_config.delete(:type) || "number"}_item", "Built", org_config.delete(:label), **org_config)
        end
        yield :original, org_item if block

        if update_expected
          expect(org_item.provider).to receive(:update).and_call_original
        else
          expect(org_item.provider).not_to receive(:update)
        end

        new_item = items.build do
          send("#{new_config.delete(:type) || "number"}_item", "Built", new_config.delete(:label), **new_config)
        end
        yield :updated, new_item if block

        [org_item, new_item]
      end

      context "with changes" do
        it "replaces the old item when the item type is different" do
          build_and_update({ type: "switch" }, { type: "string" })
          expect(item).to be_a_string_item
        end

        it "replaces the old item when the label is different" do
          build_and_update({ label: "Old Label" }, { label: "New Label" })
          expect(item.label).to eql "New Label"
        end

        it "replaces the old item when the dimension is different" do
          build_and_update({ dimension: "Power" }, { dimension: "Length" })
          expect(item.dimension.ruby_class).to be javax.measure.quantity.Length
        end

        it "replaces the old item when a unit is added" do
          build_and_update({}, { unit: "W" })
          expect(item.unit.to_s).to eql "W"
        end

        it "replaces the old item when a unit is removed" do
          build_and_update({ unit: "W" }, {})
          expect(item.unit).to be_nil
        end

        it "replaces the old item when the groups changed" do
          build_and_update({ group: "Group1" }, { groups: %w[Group1 Group2] })
          expect(item.group_names).to match_array %w[Group1 Group2]
        end

        it "replaces the old item when the tags changed" do
          build_and_update({ tags: %w[Tag1 Tag2 Light] }, { tags: %w[Tag1 Tag2] }) do |built, item|
            expect(item.metadata[:semantics]).not_to be_nil if built == :original
          end
          expect(item.tags).to match_array %w[Tag1 Tag2]
          expect(item.metadata[:semantics]).to be_nil
        end

        it "replaces the old item when icon is different" do
          build_and_update({ icon: :light }, {}) do |built, item|
            case built
            when :original then expect(item.category).to eql "light"
            when :updated then expect(item.category).to be_nil
            end
          end
        end

        it "keeps the old item but updates its links when the channels are different" do
          things.build do
            thing "a:b:c" do
              channel "old", "number"
              channel "new", "number"
            end
          end
          build_and_update({ channel: "a:b:c:old" }, { channel: "a:b:c:new" }, update_expected: false)
          expect(item.links.map(&:linked_uid)).to match_array(things["a:b:c"].channels["new"].uid)
        end

        it "keeps the old item but updates its links when the channel configs are different" do
          things.build do
            thing "a:b:c" do
              channel "d", "number"
            end
          end
          build_and_update({ channel: ["a:b:c:d", { foo: "bar" }] },
                           { channel: ["a:b:c:d", { foo: "qux" }] },
                           update_expected: false)
          link = item.links.first
          expect(link.linked_uid).to eql things["a:b:c"].channels["d"].uid
          expect(link.configuration).to eq({ "foo" => "qux" })
        end

        it "replaces the old item when necessary but verifies that channels remain the same" do
          things.build do
            thing "a:b:c" do
              channel "d", "number"
            end
          end
          channel_config = { "foo" => "bar" }.freeze
          build_and_update({ channel: ["a:b:c:d", channel_config] },
                           { channel: ["a:b:c:d", channel_config], label: "x" })
          link = item.links.first
          expect(link.linked_uid).to eql things["a:b:c"].channels["d"].uid
          expect(link.configuration).to eq channel_config
        end

        it "keeps the old item but delete its metadata when the new item has no metadata" do
          build_and_update({ metadata: { foo: "baz" } }, {}, update_expected: false)
          expect(item.metadata.key?(:foo)).to be false
        end

        it "keeps the old item but reset to the new metadata" do
          build_and_update({ metadata: { foo: "bar", moo: "cow" } },
                           { metadata: { foo: "baz", qux: "quux" } },
                           update_expected: false)
          expect(item.metadata[:foo].value).to eq "baz"
          expect(item.metadata[:qux].value).to eq "quux"
          expect(item.metadata.key?(:moo)).to be false
        end

        it "works when there's a special semantics (unmanaged) metadata" do
          build_and_update({ tags: "Lightbulb", metadata: { qux: "quux" } },
                           { tags: "Lightbulb", metadata: { foo: "bar" } },
                           update_expected: false) do |type, item|
            expect(item.metadata[:semantics]).not_to be_nil if type == :original
          end
          expect(item.metadata.key?(:qux)).to be false
          expect(item.metadata[:foo].value).to eql "bar"
        end

        it "keeps the old item when only the format (state description metadata) is different" do
          build_and_update({ format: "OLD %s" }, { format: "NEW %s" }, update_expected: false)
          expect(item.state_description.pattern).to eql "NEW %s"
        end

        it "keeps the old item when autoupdate (metadata) is different" do
          build_and_update({ autoupdate: true }, { autoupdate: false }, update_expected: false)
          expect(item.metadata[:autoupdate].value).to eql "false"
        end

        it "keeps the old item but remove autoupdate (metadata)" do
          build_and_update({ autoupdate: true }, {}, update_expected: false)
          expect(item.metadata.key?(:autoupdate)).to be false
        end

        it "keeps the old item but add expire (metadata)" do
          build_and_update({}, { expire: "5s" }, update_expected: false)
          expect(item.metadata[:expire].value).to eql "5s"
        end
      end

      context "with no changes" do
        it "keeps the old item" do
          properties = {
            label: "Just a label",
            tags: "Light",
            unit: "W",
            format: "%f",
            ga: "Light",
            groups: "Group1",
            icon: :light,
            autoupdate: true,
            expire: "1h",
            channel: "a:b:c:old"
          }.freeze

          build_and_update(properties, properties, update_expected: false)
        end

        it "keeps the old item but updates to the new state" do
          build_and_update({ state: 1 }, { state: 2 }, update_expected: false)
          expect(item.state).to eq 2
        end
      end
    end
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
        switch_item "MySwitch3", groups: Group1
      end
    end

    expect(MyGroupItem.members.to_a).to match_array [MySwitchItem, MySwitch2, MySwitch3]
    expect(MySwitchItem.groups).to eq [MyGroupItem]
    expect(MySwitch2.groups).to match_array [Group1, MyGroupItem]
    expect(MySwitch3.groups).to match_array [Group1, MyGroupItem]
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
      number_item "MyNumberItem2", dimension: :ElectricPotential
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem2.dimension.ruby_class).to be javax.measure.quantity.ElectricPotential
  end

  it "complains about invalid dimension" do
    expect { items.build { number_item "MyNumberItem", dimension: "Foo" } }.to raise_error(ArgumentError)
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
      number_item "ColorTempItem", unit: "mired"
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem.metadata["unit"].value).to eql "kW"
    expect(ColorTempItem.dimension.ruby_class).to be javax.measure.quantity.Temperature
    expect(ColorTempItem.metadata["unit"].value).to eql "mired"
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

  it "can set a range on a number item" do
    items.build do
      number_item "Number1", range: 5..10
      number_item "Number2", range: 2..10, step: 2
      number_item "Number3", range: Range.new(nil, 50) if RUBY_VERSION >= "2.7"
      number_item "Number4", range: 50..
    end

    expect(Number1.state_description.minimum.to_i).to be 5
    expect(Number1.state_description.maximum.to_i).to be 10
    expect(Number1.state_description.step).to be_nil
    expect(Number2.state_description.minimum.to_i).to be 2
    expect(Number2.state_description.maximum.to_i).to be 10
    expect(Number2.state_description.step.to_i).to be 2
    if RUBY_VERSION >= "2.7"
      expect(Number3.state_description.minimum).to be_nil
      expect(Number3.state_description.maximum.to_i).to be 50
    end
    expect(Number4.state_description.minimum.to_i).to be 50
    expect(Number4.state_description.maximum).to be_nil
  end

  it "can set read only" do
    items.build do
      switch_item "Switch1", read_only: true
      switch_item "Switch2", read_only: false
      switch_item "Switch3"
    end

    expect(Switch1.state_description).to be_read_only
    expect(Switch2.state_description).not_to be_read_only
    expect(Switch3.state_description).to be_nil
  end

  it "can set state options" do
    items.build do
      string_item "Text1", state_options: %w[LOCKED UNLOCKED]
      switch_item "Lock1", state_options: { ON => "LOCKED", OFF => "UNLOCKED" }
    end

    expect(Text1.state_description.options.to_h { |o| [o.value, o.label] }).to eql({
                                                                                     "LOCKED" => nil,
                                                                                     "UNLOCKED" => nil
                                                                                   })
    expect(Lock1.state_description.options.to_h { |o| [o.value, o.label] }).to eql({
                                                                                     "ON" => "LOCKED",
                                                                                     "OFF" => "UNLOCKED"
                                                                                   })
  end

  it "can set command options" do
    items.build do
      string_item "Text1", command_options: %w[LOCKED UNLOCKED]
      switch_item "Lock1", command_options: { ON => "LOCKED", OFF => "UNLOCKED" }
    end

    expect(Text1.command_description.command_options.to_h { |o| [o.command, o.label] }).to eql({
                                                                                                 "LOCKED" => nil,
                                                                                                 "UNLOCKED" => nil
                                                                                               })
    expect(Lock1.command_description.command_options.to_h { |o| [o.command, o.label] }).to eql({
                                                                                                 "ON" => "LOCKED",
                                                                                                 "OFF" => "UNLOCKED"
                                                                                               })
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
      switch_item "MySwitch5", expire: ["4h", { ignore_state_updates: true }]
      string_item "MyString", expire: [5.hours, "EXPIRED"]
    end

    expect(MySwitch1.metadata["expire"]&.value).to eq "1h"
    expect(MySwitch2.metadata["expire"]&.value).to eq "2h"
    expect(MySwitch3.metadata["expire"]&.value).to eq "3h,state=OFF"
    expect(MySwitch4.metadata["expire"]&.value).to eq "4h,command=OFF"
    expect(MySwitch5.metadata["expire"]).to eq ["4h", { "ignoreStateUpdates" => true }]
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

  context "with group items" do
    it "can create a group with a base type" do
      items.build do
        group_item "MyGroup", type: :switch
      end

      expect(MyGroup.base_item).to be_a(SwitchItem)
    end

    context "with a function" do
      it "can create a group with a function and base type and arguments" do
        items.build do
          group_item "MyGroup", type: :switch, function: "OR(ON,OFF)"
        end

        expect(MyGroup.base_item).to be_a(SwitchItem)
        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Or)
        expect(MyGroup.function.parameters.to_a).to eql [ON, OFF]
      end

      it "can create a group with a function and base type without an argument" do
        items.build do
          group_item "MyGroup", type: :number, function: "SUM"
        end

        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Sum)
        expect(MyGroup.function.parameters.to_a).to be_empty
      end

      it "can create a group with a simple COUNT function without quotes" do
        items.build do
          group_item "MyGroup", type: :number, function: "COUNT(ON)"
        end

        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Count)
        expect(MyGroup.function.parameters.to_a).to eq ["ON"]
      end

      it "can create a group with a complex COUNT function enclosed in double quotes" do
        items.build do
          group_item "MyGroup", type: :number, function: 'COUNT("(\w+\,\s\w+|[\d\/]*\,\d+\:\d*|[\w\d\:\s\-]+)")'
        end

        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Count)
        expect(MyGroup.function.parameters.to_a).to eq ['(\w+\,\s\w+|[\d\/]*\,\d+\:\d*|[\w\d\:\s\-]+)']
      end
    end
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

  it "sets initial state on a group item" do
    items.build { group_item "GroupItem1", type: :switch, state: ON }
    expect(GroupItem1.state).to be ON
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

    it "can reference a group item within the item's block" do
      items.build do
        group_item "gTestGroup"
        number_item "TestItem" do
          group gTestGroup
        end
      end
      expect(TestItem.groups).to eql [gTestGroup]
    end
  end

  context "with a thing" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"
      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
    end

    it "can link an item to a channel" do
      items.build { string_item "StringItem1", channel: "astro:sun:home:season#name" }
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "can link an item to multiple channels" do
      things.build do
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
      items.build do
        date_time_item "DateTime1" do
          channel "astro:sun:home:rise#start"
          channel "astro:moon:home:rise#start"
        end
      end
      expect(DateTime1.things).to match_array([things["astro:sun:home"], things["astro:moon:home"]])
    end

    it "accepts multiple channels in an immediate argument" do
      items.build { string_item "StringItem1", channels: ["astro:sun:home:season#name", "astro:moon:home:season#name"] }
      expect(StringItem1.things).to match [things["astro:sun:home"], things["astro:moon:home"]]
    end

    it "accepts multiple channels with config in an immediate argument" do
      items.build do
        string_item "StringItem1",
                    channels: [["astro:sun:home:season#name", { config: 1 }], "astro:moon:home:season#name"]
      end
      expect(StringItem1.things).to match [things["astro:sun:home"], things["astro:moon:home"]]
    end

    it "rejects invalid channel data" do
      expect do
        items.build { string_item "StringItem1", channels: 1 }
      end.to raise_error(ArgumentError)
    end

    it "can link to an item channel with a profile" do
      items.build do
        date_time_item "LastUpdated", channel: ["astro:sun:home:season#name", { profile: "system:timestamp-update" }]
      end
      expect(LastUpdated.thing).to be things["astro:sun:home"]
    end

    it "combines thing (string) and channel" do
      items.build do
        string_item "StringItem1", thing: "astro:sun:home", channel: "season#name"
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "combines thing and channel" do
      items.build do
        string_item "StringItem1", thing: things["astro:sun:home"], channel: "season#name"
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "can use symbolic channel" do
      items.build do
        string_item "StringItem1", thing: "astro:sun:home" do
          channel :"season#name"
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "ignores thing when channel contains multiple segments" do
      items.build do
        string_item "StringItem1", thing: "foo:baz:bar", channel: "astro:sun:home:season#name"
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "allows mixing short and fully qualified channels" do
      things.build do
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
      items.build do
        string_item "StringItem1", thing: "astro:moon:home", channel: "astro:sun:home:rise#start" do
          channel "rise#start"
        end
      end
      expect(StringItem1.things).to match_array [things["astro:sun:home"], things["astro:moon:home"]]
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

    it "item's thing overrides group's thing" do
      things.build do
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
      items.build do
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", thing: "astro:moon:home", channel: "set#start"
        end
      end
      expect(StringItem1.thing).to be things["astro:moon:home"]
    end
  end
end
