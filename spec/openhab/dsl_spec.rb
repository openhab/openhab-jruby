# frozen_string_literal: true

RSpec.describe OpenHAB::DSL do
  it "doesn't leak DSL methods onto other objects" do
    expect { 5.rule }.to raise_error(NoMethodError)
  end

  it "makes included methods available as class methods" do
    expect(described_class).to respond_to(:changed)
  end

  describe "#config_description" do
    it "works" do
      config = config_description do
        parameter "test", :text, label: "Test", description: "Test"
      end
      expect(config).to be_a(org.openhab.core.config.core.ConfigDescription)
    end

    it "can infer the group name when nested inside group" do
      config = config_description do
        group "group1" do
          parameter "test1", :text
        end
      end
      expect(config.parameters.first.group_name).to eq "group1"
    end
  end

  describe "#profile" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      end
    end

    it "works" do
      profile "use_a_different_state" do |event, callback:, item:|
        callback.send_update("bar") if event == :command_from_item
        expect(item).to eql MyString
        false
      end

      items.build do
        string_item "MyString",
                    channel: ["astro:sun:home:season#name", { profile: "ruby:use_a_different_state" }],
                    autoupdate: false
      end

      MyString << "foo"
      expect(MyString.state).to eq "bar"
    end

    it "defaults missing params to nil" do
      checked = false
      # technically we only see a command event, so state isn't provided
      profile :i_check_state do |_event, state:|
        expect(state).to be_nil
        checked = true
        false
      end

      items.build do
        string_item "MyString",
                    channel: ["astro:sun:home:season#name", { profile: "ruby:i_check_state" }],
                    autoupdate: false
      end

      MyString << "foo"
      expect(checked).to be true
    end

    it "exposes config" do
      unit = nil
      profile :i_check_config do |_event, configuration:|
        unit = configuration["unit"]
        false
      end

      items.build do
        string_item "MyString",
                    channel: ["astro:sun:home:season#name", { profile: "ruby:i_check_config", unit: "°F" }],
                    autoupdate: false
      end

      MyString << "foo"
      expect(unit).to eql "°F"
    end

    # Whilst sending a command to astro:sun:home:season#name does nothing, it's used here
    # to test that it doesn't cause any errors due to formatting being done by ProfileCallback
    it "supports sending a command to a channel that has a different type than the item" do
      profile :season_color do |callback:|
        callback.handle_command("test")
        false
      end

      items.build do
        color_item "SeasonColor", channel: ["astro:sun:home:season#name", { profile: "ruby:season_color" }]
      end

      SeasonColor << "0,100,100"
    end

    it "receives the command source", if: OpenHAB::Core.version >= OpenHAB::Core::V5_1 do
      profile :command_source do |item:, source:|
        expect(source).to eql "test_source"
        item.update("triggered")
        false
      end

      items.build do
        string_item MyString,
                    channel: ["astro:sun:home:season#name", { profile: "ruby:command_source" }],
                    autoupdate: false
      end

      MyString.command("foo", source: "test_source")
      expect(MyString.state).to eq "triggered"
    end

    context "with time series" do
      it "supports sending a time series" do
        profile :send_as_time_series do |event, callback:, command:|
          next unless event == :command_from_item

          time_series_from_command = TimeSeries.new.add(Time.now, command)
          callback.send_time_series(time_series_from_command)
          false
        end

        items.build do
          color_item "SeasonColor", channel: ["astro:sun:home:season#name", { profile: "ruby:send_as_time_series" }]
        end

        time_series = nil
        rule do
          time_series_updated SeasonColor
          run { |event| time_series = event.time_series }
        end

        SeasonColor << "0,100,100"

        expect(time_series).not_to be_nil
        expect(time_series.first.state).to eql HSBType.new("0,100,100")
      end

      it "supports time series from handler" do
        profile :send_time_series_as_update do |event, callback:, time_series:|
          next unless event == :time_series_from_handler

          callback.send_update(time_series.first.state)
          false
        end

        items.build do
          color_item "SeasonColor",
                     channel: ["astro:sun:home:season#name", { profile: "ruby:send_time_series_as_update" }]
        end

        state = nil
        updated(SeasonColor) { |event| state = event.state }

        time_series = TimeSeries.new.add(Time.now, HSBType.new("0,100,100"))
        SeasonColor.thing.handler.send_time_series(SeasonColor.channel.uid, time_series)

        expect(state).to eql HSBType.new("0,100,100")
      end
    end

    context "with UI support" do
      it "supports UI label" do
        profile("ui_profile", label: "Profile Visible in UI") { |_event| true }
      end

      it "supports config description" do
        config_description = config_description do
          parameter "test", :text, label: "Test", description: "Test"
        end

        profile(:test, label: "Test Profile", config_description:) { |_event| true }
      end
    end

    context "with trigger channels" do
      before do
        things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }
        items.build do
          string_item "MyString" do
            channel "astro:sun:home:rise#event", profile: "ruby:trigger_profile"
          end
        end
      end

      it "works" do
        triggered_event = nil
        profile(:trigger_profile) { |event, trigger:| triggered_event = trigger if event == :trigger_from_handler }
        trigger_channel("astro:sun:home:rise#event", "START")

        expect(triggered_event).to eql "START"
      end
    end
  end

  describe "#rule" do
    it "infers the rule id and generate unique id to avoid conflicts" do
      created_rules = (1..2).map do
        rule "MyRule" do
          every :day
          run { nil }
        end
      end
      expect(created_rules.compact.size).to eq 2
      expect(created_rules.map(&:uid).uniq.size).to eq 2
      expect(created_rules.filter_map { |r| rules[r.uid] }.size).to eq 2
    end

    it "fails and returns nil when an an existing id is given" do
      rule_id = "myrule"

      rule "Original rule", id: rule_id do
        every :day
        run { nil }
      end
      expect(rules[rule_id]).not_to be_nil

      new_rule = rule "Rule 1", id: rule_id do
        every :day
        run { nil }
      end
      expect(new_rule).to be_nil

      new_rule = rule "Rule 2" do
        every :day
        uid rule_id
        run { nil }
      end
      expect(new_rule).to be_nil

      expect(rules[rule_id].name).to eql "Original rule"
    end
  end

  describe "#rule!" do
    it "infers the id but removes the existing rule with the same inferred id" do
      created_rules = (1..2).map do |i|
        rule! "Rule #{i}" do
          every :day
          run { nil }
        end
      end
      expect(created_rules.map(&:uid).uniq.size).to eq 1
      expect(rules[created_rules.first.uid].name).to eq "Rule #{created_rules.length}"
    end

    it "replaces the existing rule with the same id" do
      rule_id = "myrule"
      rule "Original Rule", id: rule_id do
        every :day
        run { nil }
      end
      expect(rules[rule_id].name).to eql "Original Rule"

      rule! "NewRule", id: rule_id do
        every :day
        run { nil }
      end
      expect(rules[rule_id].name).to eql "NewRule"
    end
  end

  describe "#script" do
    it "creates triggerable rule" do
      triggered = false
      script id: "testscript" do
        triggered = true
      end

      rules["testscript"].trigger
      expect(triggered).to be true
    end

    it "can access its context" do
      received_context = nil
      script id: "testscript" do
        received_context = foo
      end

      rules["testscript"].trigger(nil, foo: "bar")
      expect(received_context).to eql "bar"
    end
  end

  describe "#script!" do
    it "replaces the existing script with the same id" do
      script_id = "myscript"
      script("Original Script", id: script_id) { nil }
      expect(rules[script_id].name).to eql "Original Script"

      script!("NewScript", id: script_id) { nil }
      expect(rules[script_id].name).to eql "NewScript"
    end
  end

  describe "#scene" do
    it "creates triggerable scene" do
      triggered = false
      scene id: "testscene" do
        triggered = true
      end

      rules.scenes["testscene"].trigger
      expect(triggered).to be true
    end

    it "can access its context" do
      received_context = nil
      scene id: "testscene" do
        received_context = foo
      end

      rules["testscene"].trigger(nil, foo: "bar")
      expect(received_context).to eql "bar"
    end
  end

  describe "#scene!" do
    it "replaces the existing scene with the same id" do
      scene_id = "myscene"
      scene("Original Scene", id: scene_id) { nil }
      expect(rules[scene_id].name).to eql "Original Scene"

      scene!("NewScene", id: scene_id) { nil }
      expect(rules[scene_id].name).to eql "NewScene"
    end
  end

  describe "#store_states" do
    before do
      items.build do
        switch_item "Switch1", state: OFF
        switch_item "Switch2", state: OFF
      end
    end

    it "stores and restores states" do
      states = store_states Switch1, Switch2
      Switch1.on
      expect(Switch1).to be_on
      states.restore
      expect(Switch1).to be_off
    end

    it "restores states after the block returns" do
      store_states Switch1, Switch2 do
        Switch1.on
        expect(Switch1).to be_on
      end
      expect(Switch1).to be_off
    end
  end

  describe "#debounce" do
    it "works" do
      counter = 0
      Timecop.freeze do
        20.times do
          debounce(for: 100.ms) { counter += 1 }
          time_travel_and_execute_timers(10.ms)
        end
        expect(counter).to eq 2
      end
    end

    it "returns the debouncer object" do
      debouncer = debounce(for: 100.ms) { nil }
      expect(debouncer).to be_a(OpenHAB::DSL::Debouncer)
    end
  end

  describe "#debounce_for" do
    it "works" do
      exec_counter = 0
      Timecop.freeze do
        20.times do
          debounce_for(100.ms) { exec_counter += 1 }
          time_travel_and_execute_timers(10.ms)
          expect(exec_counter).to eq 0
        end
        time_travel_and_execute_timers(90.ms)
        expect(exec_counter).to eq 1
      end
    end

    it "supports a range of period" do
      exec_counter = 0
      call_counter = 0
      Timecop.freeze do
        20.times do
          debounce_for((100.ms)..(150.ms)) { exec_counter += 1 }
          call_counter += 1
          time_travel_and_execute_timers(10.ms)
          expect(exec_counter).to eq (call_counter / 15).floor
        end
        time_travel_and_execute_timers(90.ms)
        expect(exec_counter).to eq 2
      end
    end
  end

  describe "#throttle_for" do
    it "works" do
      counter = 0
      Timecop.freeze do
        20.times do
          throttle_for(100.ms) { counter += 1 }
          time_travel_and_execute_timers(10.ms)
        end
        expect(counter).to eq 2
      end
    end
  end

  describe "#only_every" do
    it "works" do
      counter = 0
      Timecop.freeze do
        20.times do
          only_every(100.ms) { counter += 1 }
          time_travel_and_execute_timers(10.ms)
        end
        expect(counter).to eq 2
      end
    end

    it "accepts symbolic duration" do
      %i[second minute hour day].each do |sym|
        expect { only_every(sym) { nil } }.not_to raise_exception
      end
    end
  end

  describe "#persistence" do
    before { items.build { switch_item "Item1" } }

    it "works" do
      expect(OpenHAB::Core::Actions::PersistenceExtensions).to receive(:last_update).with(Item1, nil)
      Item1.last_update
      expect(OpenHAB::Core::Actions::PersistenceExtensions).to receive(:last_update).with(Item1, "influxdb")
      persistence(:influxdb) { Item1.last_update }
    end

    it "can permanently set persistence service" do
      expect(OpenHAB::Core::Actions::PersistenceExtensions).to receive(:last_update).with(Item1, nil)
      Item1.last_update
      persistence!(:influxdb)
      expect(OpenHAB::Core::Actions::PersistenceExtensions).to receive(:last_update).with(Item1, "influxdb")
      Item1.last_update
    end
  end

  describe "#unit" do
    it "converts all units and numbers to specific unit for all operations" do
      c = 23 | "°C"
      f = 70 | "°F"
      # f.to_unit(SIUnits::CELSIUS) = 21.11 °C
      # f.to_unit_relative(SIUnits::CELSIUS) = 38.89 °C
      unit("°F") do
        expect(c - f < 4).to be true
        expect(c - (24 | "°C") < 32).to be true
        expect(QuantityType.new("24 °C") - c < 34).to be true
      end

      unit("°C") do
        expect(f - (20 | "°C") < 2).to be true
        expect((f - 2).format("%.1f %unit%")).to eq "19.1 °C"
        expect((c + f).format("%.1f %unit%")).to eq "61.9 °C"
        expect(f - 2 < 20).to be true
        expect(40 - f < 2).to be true
        expect(2 + c == 25).to be true
        expect(c + 2 == 25).to be true
        expect([c, f, 2].min).to be 2
      end

      # The behavior of Multiplications and Divisions with non zero-based units such as °C and °F
      # (as opposed to Kelvin) is different between OH 4.1 and previous versions.
      # See https://github.com/openhab/openhab-core/pull/3792
      # Use a zero-based unit to have a consistent result across OH versions.
      w = 5 | "W"
      kw = 5 | "kW"
      unit("W") do
        # numeric rhs
        expect(w * 2 == 10).to be true
        expect((kw * 2).format("%.0f %unit%")).to eq "10000 W"
        expect(w / 5).to eql 1 | "W"
        # numeric lhs
        expect(2 * w).to eql 10 | "W"
        expect((2 * kw).to_i).to eq 10_000
        expect(2 * w == 10).to be true
        expect(5 / w).to eql 1 | "/W"
        expect(2 * w / 2).to eql w
        expect(2 * w / 2).not_to eql(kw)
      end
    end

    it "supports setting multiple dimensions at once" do
      unit("°C", "ft") do
        expect(1 | "yd").to eq 3
        expect(32 | "°F").to eq 0
      end
    end

    it "can permanently set units" do
      unit!("ft")
      expect(unit(SIUnits::METRE.dimension)).to be ImperialUnits::FOOT
      unit!
      expect(unit(SIUnits::METRE.dimension)).to be_nil
    ensure
      unit!
    end
  end

  describe "provider" do
    before do
      items.build do
        switch_item "Switch1"
        switch_item "Switch2"
      end
    end

    let(:provider_class) { OpenHAB::Core::Items::Metadata::Provider }
    let(:registry) { provider_class.registry }
    let(:managed_provider) { registry.managed_provider.get }

    around do |example|
      provider_class.new(thread_provider: false) do |provider|
        example.example_group.let!(:other_provider) { provider }
        example.call
      ensure
        provider.unregister
      end
    end

    it "type checks providers" do
      expect do
        provider(metadata: :other_provider) { nil }
      end.to raise_error(ArgumentError, /not a valid provider/)
    end

    it "type checks proc providers when they're used" do
      provider(metadata: -> { :other_provider }) do
        expect { provider_class.current }.to raise_error(ArgumentError)
      end
    end

    it "can use a single provider for all" do
      provider(:persistent) do
        expect(provider_class.current).to be managed_provider
      end
    end

    it "can set a proc as a provider" do
      provider(-> { :persistent }) do
        expect(provider_class.current).to be managed_provider
      end
    end

    it "can set a provider explicitly" do
      provider(other_provider) do
        expect(provider_class.current).to be other_provider
        expect(OpenHAB::Core::Items::Provider.current).not_to be other_provider
      end
    end

    it "can set a managed provider explicitly" do
      provider(managed_provider) do
        expect(provider_class.current).to be managed_provider
        expect(OpenHAB::Core::Items::Provider.current).not_to be managed_provider
      end
    end

    it "can set a provider for metadata namespaces" do
      provider(namespace1: other_provider) do
        Switch1.metadata[:namespace1] = "hi"
        Switch1.metadata[:namespace2] = "bye"
        m1 = Switch1.metadata[:namespace1]
        m2 = Switch1.metadata[:namespace2]
        expect(registry.provider_for(m1.uid)).to be other_provider
        expect(registry.provider_for(m2.uid)).to be provider_class.current
      end
    end

    it "can set a provider for metadata items" do
      provider(Switch1 => other_provider) do
        Switch1.metadata[:test] = "hi"
        Switch2.metadata[:test] = "bye"
        m1 = Switch1.metadata[:test]
        m2 = Switch2.metadata[:test]
        expect(registry.provider_for(m1.uid)).to be other_provider
        expect(registry.provider_for(m2.uid)).to be provider_class.current
      end
    end

    it "can set a provider for metadata with a Proc" do
      original_provider = provider_class.current
      my_proc = proc do |metadata|
        (metadata&.item == Switch1) ? other_provider : original_provider
      end

      provider(metadata: my_proc) do
        Switch1.metadata[:test] = "hi"
        Switch2.metadata[:test] = "bye"
        m1 = Switch1.metadata[:test]
        m2 = Switch2.metadata[:test]
        expect(registry.provider_for(m1.uid)).to be other_provider
        expect(registry.provider_for(m2.uid)).to be original_provider
      end
    end

    it "prevents setting providers for the wrong type" do
      expect { provider(things: other_provider) { nil } }.to raise_error(ArgumentError, /is not a provider for things/)
    end

    it "doesn't have zombie metadata across recreated items" do
      # nest the items.build in blocks as if they're in their own script files
      OpenHAB::Core::Items::Provider.new do
        provider_class.new do
          items.build do
            switch_item "Switch3", metadata: { test: "hi" }
          end
          expect(Switch3.metadata[:test].value).to eql "hi"
        end
      end
      expect(items).not_to have_key("Switch3")

      OpenHAB::Core::Items::Provider.new do
        provider_class.new do
          items.build do
            switch_item "Switch3"
          end
          expect(Switch3.metadata).not_to have_key(:test)
        end
      end
    end
  end
end
