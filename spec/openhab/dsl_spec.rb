# frozen_string_literal: true

RSpec.describe OpenHAB::DSL do
  it "doesn't leak DSL methods onto other objects" do
    expect { 5.rule }.to raise_error(NoMethodError)
  end

  it "makes included methods available as class methods" do
    expect(described_class).to respond_to(:changed)
  end

  describe "#profile" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      end
    end

    it "works" do
      profile "use_a_different_state" do |_event, callback:, item:|
        callback.send_update("bar")
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
      20.times do
        debounce(for: 100.ms) { counter += 1 }
        time_travel_and_execute_timers(10.ms)
      end
      expect(counter).to eq 2
    end

    it "returns the debouncer object" do
      debouncer = debounce(for: 100.ms) { nil }
      expect(debouncer).to be_a(OpenHAB::DSL::Debouncer)
    end
  end

  describe "#debounce_for" do
    it "works" do
      exec_counter = 0
      20.times do
        debounce_for(100.ms) { exec_counter += 1 }
        time_travel_and_execute_timers(10.ms)
        expect(exec_counter).to eq 0
      end
      time_travel_and_execute_timers(90.ms)
      expect(exec_counter).to eq 1
    end

    it "supports a range of period" do
      exec_counter = 0
      call_counter = 0
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

  describe "#throttle_for" do
    it "works" do
      counter = 0
      20.times do
        throttle_for(100.ms) { counter += 1 }
        time_travel_and_execute_timers(10.ms)
      end
      expect(counter).to eq 2
    end
  end

  describe "#only_every" do
    it "works" do
      counter = 0
      20.times do
        only_every(100.ms) { counter += 1 }
        time_travel_and_execute_timers(10.ms)
      end
      expect(counter).to eq 2
    end

    it "accepts symbolic duration" do
      %i[second minute hour day].each do |sym|
        expect { only_every(sym) { nil } }.not_to raise_exception
      end
    end
  end

  describe "#unit" do
    it "converts all units and numbers to specific unit for all operations" do
      c = 23 | "°C"
      f = 70 | "°F"
      unit("°F") do
        expect(c - f < 4).to be true
        expect(c - (24 | "°C") < 4).to be true
        expect(QuantityType.new("24 °C") - c < 4).to be true
      end

      unit("°C") do
        expect(f - (20 | "°C") < 2).to be true
        expect((f - 2).format("%.1f %unit%")).to eq "19.1 °C" # rubocop:disable Style/FormatStringToken
        expect((c + f).format("%.1f %unit%")).to eq "44.1 °C" # rubocop:disable Style/FormatStringToken
        expect(f - 2 < 20).to be true
        expect(2 + c == 25).to be true
        expect(2 * c == 46).to be true
        expect((2 * (f + c) / 2) < 45).to be true
        expect([c, f, 2].min).to be 2
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
