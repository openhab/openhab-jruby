# frozen_string_literal: true

require "tmpdir"
require "securerandom"

RSpec.describe OpenHAB::DSL::Rules::Builder do
  it "doesn't create a rule if there are no execution blocks" do
    rule(id: "test_rule") { on_load }

    expect($rules.get("test_rule")).to be_nil
    expect(spec_log_lines).to include(include("has no execution blocks, not creating rule"))
  end

  it "can access items from the rule block" do
    items.build do
      switch_item "lowerCaseSwitchItem"
      switch_item "UpperCaseSwitchItem"
    end

    rspec = self
    rule do
      rspec.expect(lowerCaseSwitchItem).not_to rspec.be_nil
      rspec.expect(UpperCaseSwitchItem).not_to rspec.be_nil
      rspec.expect(items["lowerCaseSwitchItem"]).not_to rspec.be_nil
    end
  end

  describe "triggers" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"
    end

    def self.test_thing_status_trigger(trigger, from: nil, to: nil, duration: nil, expect_triggered: true, &block)
      description = "supports status #{trigger} trigger"
      description += " from: #{from.inspect}" if from
      description += " to: #{to.inspect}" if to
      description += " for: #{duration.inspect}" if duration
      callers = caller
      id = callers.first.split("/").last.rpartition(":").first

      it description, caller: callers do
        # this is the only way to make this accessible to both
        # the rule where it's set, and to the block given to the
        # definition method
        @triggered = false

        class << self
          attr_writer :triggered

          def triggered?
            @triggered # rubocop:disable RSpec/InstanceVariable
          end
        end

        rule "Execute rule when thing is #{trigger}", id: id do
          kwargs = { to: to }
          kwargs[:from] = from if from
          kwargs[:for] = duration if duration

          send(trigger, things["astro:sun:home"], **kwargs)
          run { self.triggered = true }
        end
        expect(thing.status.to_s).to eq "ONLINE"
        thing.disable
        expect(thing.status.to_s).to eq "UNINITIALIZED"
        if block
          instance_eval(&block)
        else
          expect(triggered?).to be expect_triggered
        end
      end
    end

    describe "#on_load" do
      it "works" do
        executed = false
        rule do
          on_load
          run { executed = true }
        end
        expect(executed).to be true
      end

      it "can use a delay" do
        executed = false
        rule do
          on_load delay: 500.ms
          run { executed = true }
        end
        expect(executed).to be false
        time_travel_and_execute_timers(800.ms)
        expect(executed).to be true
      end
    end

    describe "#on_start" do
      it "works with default level" do
        rule = rule do
          on_start
          run { nil }
        end
        t = rule.triggers.first
        expect(t.type_uid).to eql "core.SystemStartlevelTrigger"
        expect(t.configuration.properties.key?("startlevel")).to be true
        expect(t.configuration.properties["startlevel"].to_i).to eq 100
      end

      # @param [Symbol,Integer,Array<Symbol>,Array<Integer>] level
      # @param [Integer,Array<Integer>] raw_level
      def test_on_start(level, raw_level = nil)
        rule = rule do
          if level.is_a?(Array)
            on_start at_levels: level
          else
            on_start at_level: level
          end
          run { nil }
        end

        level = Array.wrap(level)
        raw_level = raw_level ? Array.wrap(raw_level) : level

        rule.triggers.each_with_index do |trigger, i|
          expect(trigger.type_uid).to eql "core.SystemStartlevelTrigger"
          expect(trigger.configuration.properties.key?("startlevel")).to be true
          expect(trigger.configuration.properties["startlevel"].to_i).to eq raw_level[i]
        end
      end

      it "works with numeric at_level" do
        [40, 50, 70, 80, 100].each { |level| test_on_start(level) }
      end

      it "works with symbolic at_level" do
        { rules: 40, ruleengine: 50, ui: 70, things: 80, complete: 100 }.each do |symbol, numeric|
          test_on_start(symbol, numeric)
        end
      end

      it "works with numeric at_levels" do
        test_on_start([40, 50, 70, 80, 100])
      end

      it "works with symbolic at_levels" do
        test_on_start(%i[rules ruleengine ui things complete], [40, 50, 70, 80, 100])
      end

      it "raises an exception with invalid symbols" do
        %i[foo baz].each do |level|
          expect do
            rule do
              on_start at_level: level
              run { nil }
            end
          end.to raise_exception(ArgumentError)
        end
      end
    end

    describe "#changed" do
      it "complains about invalid data type" do
        expect do
          changed([OpenHAB::Core::Things::ThingUID.new("astro:sun:home")]) do
            nil
          end
        end.to raise_error(ArgumentError)
        expect { changed("StringItemName") { nil } }.to raise_error(ArgumentError)
        expect { changed(5) { nil } }.to raise_error(ArgumentError)
      end

      context "with items" do
        before do
          items.build do
            number_item "Alarm_Mode1"
            number_item "Alarm_Mode2"
            group_item "Switches", type: :switch, function: "OR(ON,OFF)" do
              switch_item "Switch1"
            end
          end
        end

        def self.test_changed_trigger(
          item = "Alarm_Mode1",
          initial_state: nil,
          new_state: 9,
          from: nil,
          to: nil,
          duration: nil,
          expect_triggered: true,
          caller: Kernel.caller,
          &block
        )
          description = "supports changed trigger on #{item}"
          description += " with initial state #{initial_state}" if initial_state
          description += " from: #{from.inspect}" if from
          description += " to: #{to.inspect}" if to
          description += " for: #{duration.inspect}" if duration

          it description, caller: caller do
            # this is the only way to make this accessible to both
            # the rule where it's set, and to the block given to the
            # definition method
            @triggered_item = nil

            class << self
              attr_accessor :triggered_item
            end

            trigger_items = eval("[#{item}]", nil, __FILE__, __LINE__) # rubocop:disable Security/Eval
            trigger_items.first.update(initial_state) if initial_state
            rule "Execute rule when item changes" do
              changed(*trigger_items, from: from, to: to, for: duration)
              run { |event| self.triggered_item = event.item.name }
            end
            if block
              instance_eval(&block)
            else
              item_to_update = items[expect_triggered] || trigger_items.first
              item_to_update.update(new_state)
              expect_triggered = item if expect_triggered == true
              expect(triggered_item).to eql expect_triggered
            end
          end
        end

        test_changed_trigger(to: 14, new_state: 14)
        test_changed_trigger(to: [10, 14], new_state: 10)
        test_changed_trigger(to: [10, 14], new_state: 7, expect_triggered: nil)
        test_changed_trigger(new_state: 7)
        test_changed_trigger("Switches", new_state: ON) do
          Switches.on
          expect(triggered_item).to eq "Switches"
        end
        test_changed_trigger("Switches.members", new_state: ON, expect_triggered: "Switch1")
        test_changed_trigger("Switches.members") do
          items.build { switch_item "Switch2", group: Switches }
          Switch2.on
          expect(triggered_item).to eql "Switch2"
        end
        test_changed_trigger("Switch1", initial_state: OFF, new_state: OFF, expect_triggered: nil)
        test_changed_trigger("Switch1", initial_state: OFF, new_state: ON)
        test_changed_trigger("Switch1", initial_state: ON, new_state: ON, expect_triggered: nil)
        test_changed_trigger("Switch1", initial_state: ON, new_state: OFF)
        test_changed_trigger("Alarm_Mode1, Alarm_Mode2",
                             new_state: 3,
                             expect_triggered: "Alarm_Mode1")
        test_changed_trigger("Alarm_Mode1, Alarm_Mode2",
                             new_state: 4,
                             expect_triggered: "Alarm_Mode2")

        test_changed_trigger(initial_state: 10, from: [10, 14], new_state: 11)
        test_changed_trigger(initial_state: 11,
                             from: [10, 14],
                             new_state: 12,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 14, from: [10, 14], new_state: 15)
        test_changed_trigger(initial_state: 10, from: 8..10, new_state: 14)
        test_changed_trigger(initial_state: 15,
                             from: 4..12,
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4, to: 8..10)
        test_changed_trigger(initial_state: 11,
                             to: 4..12,
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4, from: 2..5, to: 8..10)
        test_changed_trigger(initial_state: 4,
                             from: 5..6,
                             to: 8..10,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: 2..5,
                             to: 8..12,
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4, to: 8..)
        test_changed_trigger(initial_state: 4,
                             to: 15..,
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 10, from: ->(f) { f == 10 }) { Alarm_Mode1.update(14) }
        test_changed_trigger(initial_state: 15,
                             from: ->(f) { f == 10 },
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 10, from: proc { |f| f == 10 }) { Alarm_Mode1.update(14) }
        test_changed_trigger(initial_state: 15,
                             from: proc { |f| f == 10 },
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             to: ->(t) { t == 9 })
        test_changed_trigger(initial_state: 11,
                             to: ->(t) { t == 9 },
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             to: proc { |t| t == 9 })
        test_changed_trigger(initial_state: 11,
                             to: proc { |t| t == 9 },
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: ->(_f) { true },
                             to: ->(_t) { true })
        test_changed_trigger(initial_state: 4,
                             from: ->(_f) { false },
                             to: ->(_t) { true },
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: ->(_f) { true },
                             to: ->(_t) { false },
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: ->(_f) { false },
                             to: ->(_t) { false },
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: proc { true },
                             to: proc { true })
        test_changed_trigger(initial_state: 4,
                             from: proc { false },
                             to: proc { true },
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: proc { true },
                             to: proc { false },
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: proc { false },
                             to: proc { false },
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: proc { true },
                             to: 8..10)
        test_changed_trigger(initial_state: 4,
                             from: proc { true },
                             to: 8..10,
                             new_state: 14,
                             expect_triggered: nil)
        test_changed_trigger(initial_state: 4,
                             from: 4..10,
                             to: proc { true })
        test_changed_trigger(initial_state: 4,
                             from: 4,
                             to: proc { true })

        describe "duration" do
          before do
            items.build { number_item "Alarm_Delay", state: 5 }
          end

          def self.test_changed_trigger(item = "Alarm_Mode1",
                                        initial_state: 8,
                                        new_state: 14,
                                        duration: 5.seconds,
                                        expect_triggered: item,
                                        **kwargs,
                                        &block)
            block ||= proc do
              items[item].update(new_state)
              execute_timers
              expect(triggered_item).to be_nil
              time_travel_and_execute_timers(10.seconds)
              expect(triggered_item).to eql expect_triggered
            end

            kwargs[:caller] ||= caller
            super(item, initial_state: initial_state, duration: duration, **kwargs, &block)
          end

          test_changed_trigger(duration: -> { Alarm_Delay.state.to_i.seconds })
          test_changed_trigger(to: 14)
          test_changed_trigger(to: 14, new_state: 10, expect_triggered: nil)
          test_changed_trigger(from: 8, to: 14)
          test_changed_trigger(from: 10, to: 14, new_state: 10, expect_triggered: nil)
          test_changed_trigger(to: [10, 14])
          test_changed_trigger(from: [8, 10], to: 14)
          test_changed_trigger(from: [8, 10], to: [11, 14])
          test_changed_trigger(from: [8, 10], to: [11, 14], new_state: 12, expect_triggered: nil)
          test_changed_trigger(from: [8, 10], to: [9, 10], expect_triggered: nil)
          test_changed_trigger(duration: 10.seconds) do
            Alarm_Mode1.update(14)
            execute_timers
            expect(triggered_item).to be_nil
            time_travel_and_execute_timers(5.seconds)
            expect(triggered_item).to be_nil
            Alarm_Mode1.update(10)
            execute_timers
            expect(triggered_item).to be_nil
            time_travel_and_execute_timers(30.seconds)
            expect(triggered_item).to eql "Alarm_Mode1"
          end
          test_changed_trigger(to: 14, duration: 10.seconds) do
            Alarm_Mode1.update(14)
            execute_timers
            expect(triggered_item).to be_nil
            time_travel_and_execute_timers(5.seconds)
            expect(triggered_item).to be_nil
            Alarm_Mode1.update(10)
            execute_timers
            expect(triggered_item).to be_nil
            time_travel_and_execute_timers(20.seconds)
            expect(triggered_item).to be_nil
          end

          context "without to state" do
            test_changed_trigger(from: 8) do
              Alarm_Mode1.update(10)
              time_travel_and_execute_timers(4.seconds)
              expect(triggered_item).to be_nil
              time_travel_and_execute_timers(2.seconds)
              expect(triggered_item).to eql "Alarm_Mode1"
            end

            context "when state changes more than once" do # rubocop:disable RSpec/EmptyExampleGroup examples are dynamically generated
              test_changed_trigger(from: 8) do
                Alarm_Mode1.update(10)
                time_travel_and_execute_timers(4.seconds)
                expect(triggered_item).to be_nil
                Alarm_Mode1.update(20)
                execute_timers
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(2.seconds)
                expect(triggered_item).to eql "Alarm_Mode1"
              end

              test_changed_trigger(from: [7, 8]) do
                Alarm_Mode1.update(10)
                time_travel_and_execute_timers(4.seconds)
                expect(triggered_item).to be_nil
                Alarm_Mode1.update(20)
                execute_timers
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(2.seconds)
                expect(triggered_item).to eql "Alarm_Mode1"
              end
            end

            context "when state changes back to the from state" do # rubocop:disable RSpec/EmptyExampleGroup examples are dynamically generated
              test_changed_trigger(from: 8) do
                Alarm_Mode1.update(10)
                time_travel_and_execute_timers(4.seconds)
                expect(triggered_item).to be_nil
                Alarm_Mode1.update(8) # reverts back to from state, it should cancel the trigger
                execute_timers
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(2.seconds)
                expect(triggered_item).to be_nil
              end

              test_changed_trigger(from: [7, 8]) do
                Alarm_Mode1.update(10)
                time_travel_and_execute_timers(4.seconds)
                expect(triggered_item).to be_nil
                Alarm_Mode1.update(8) # reverts back to from state, it should cancel the trigger
                execute_timers
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(2.seconds)
                expect(triggered_item).to be_nil
              end
            end
          end

          context "with a numeric group item" do
            before do
              items.build do
                group_item "Modes" do
                  number_item "Alarm_Mode3", state: 0
                  number_item "Alarm_Mode4"
                end
              end
            end

            def self.test_changed_trigger(item, new_state: 14, expect_triggered: "Alarm_Mode4", **kwargs)
              super(item, caller: caller, **kwargs) do
                Alarm_Mode4.update(new_state)
                execute_timers
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(3.seconds)
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(5.seconds)
                expect(triggered_item).to eql expect_triggered
              end
            end
            test_changed_trigger("Modes.members")
            test_changed_trigger("Modes.members", to: 14)
            test_changed_trigger("Modes.members", to: 14, new_state: 10, expect_triggered: nil)
            test_changed_trigger("Modes.members", from: 8, to: 14)
            test_changed_trigger("Modes.members", from: 10, to: 14, new_state: 10, expect_triggered: nil)

            it "handles multiple members changing" do
              executed_items = []

              rule do
                changed Modes.members, to: 3, for: 10.seconds
                run { |event| executed_items << event.item }
              end

              Alarm_Mode3.update(3)
              time_travel_and_execute_timers(5.seconds)
              Alarm_Mode4.update(5)
              Alarm_Mode4.update(3)
              # should not reset the timer on the first item
              time_travel_and_execute_timers(7.seconds)

              expect(executed_items).to eq [Alarm_Mode3]

              time_travel_and_execute_timers(5.seconds)
              expect(executed_items).to eq [Alarm_Mode3, Alarm_Mode4]
            end
          end

          context "with a switch group item" do # rubocop:disable RSpec/EmptyExampleGroup examples are dynamically generated
            before do
              items.build do
                switch_item "Switch2", group: Switches
              end
              Switch1.off
            end

            def self.test_changed_trigger(item,
                                          initial_state: OFF,
                                          new_state: ON,
                                          expect_triggered: "Switches",
                                          **kwargs)
              super(item, initial_state: initial_state, caller: caller, **kwargs) do
                Switch2.update(new_state)
                execute_timers
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(3.seconds)
                expect(triggered_item).to be_nil
                time_travel_and_execute_timers(5.seconds)
                expect(triggered_item).to eql expect_triggered
              end
            end
            test_changed_trigger("Switches")
            test_changed_trigger("Switches", to: ON)
            test_changed_trigger("Switches", to: ON, initial_state: ON, new_state: OFF, expect_triggered: nil)
            test_changed_trigger("Switches", from: OFF, to: ON)
            test_changed_trigger("Switches", from: ON, to: ON, expect_triggered: nil)
          end
        end

        context "with dummy proxies" do
          it "handles items that are constants" do
            triggered = false
            rule do
              changed ItemThatDoesntYetExist
              run { triggered = true }
            end

            items.build { switch_item "ItemThatDoesntYetExist" }
            expect(triggered).to be false
            ItemThatDoesntYetExist.on
            expect(triggered).to be true
          end

          it "handles items that are not constants" do
            triggered = false
            rule do
              changed gItemThatDoesntYetExist
              run { triggered = true }
            end

            items.build { switch_item "gItemThatDoesntYetExist" }
            expect(triggered).to be false
            gItemThatDoesntYetExist.on
            expect(triggered).to be true
          end

          it "handles group members" do
            triggered = false
            rule do
              changed gItemThatDoesntYetExist.members
              run { triggered = true }
            end

            items.build do
              group_item "gItemThatDoesntYetExist", type: :switch, function: "OR(ON,OFF)" do
                switch_item "Switch2"
              end
            end
            expect(triggered).to be false
            Switch2.on
            expect(triggered).to be true
          end
        end
      end

      context "with things" do
        let!(:thing) do
          things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }
        end

        test_thing_status_trigger(:changed)
        test_thing_status_trigger(:changed, to: :uninitialized)
        test_thing_status_trigger(:changed, to: :unknown, expect_triggered: false)
        test_thing_status_trigger(:changed, from: :online)
        test_thing_status_trigger(:changed, from: :unknown, expect_triggered: false)
        test_thing_status_trigger(:changed, from: :online, to: :uninitialized)
        test_thing_status_trigger(:changed, from: :unknown, to: :uninitialized, expect_triggered: false)
        test_thing_status_trigger(:changed, to: :uninitialized, duration: 10.seconds) do |_triggered|
          execute_timers
          expect(triggered?).to be false
          time_travel_and_execute_timers(15.seconds)
          expect(triggered?).to be true
        end
        test_thing_status_trigger(:changed, to: :uninitialized, duration: 20.seconds) do |_triggered|
          execute_timers
          expect(triggered?).to be false
          thing.enable
          time_travel_and_execute_timers(5.seconds)
          expect(triggered?).to be false
          time_travel_and_execute_timers(20.seconds)
          expect(triggered?).to be false
        end

        it "supports ThingUID" do
          triggered = false
          changed things["astro:sun:home"].uid do
            triggered = true
          end
          thing.disable
          expect(triggered).to be true
        end
      end
    end

    describe "#channel" do # rubocop:disable RSpec/EmptyExampleGroup examples are dynamically generated
      before do
        things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }
      end

      def self.test_channel_trigger(channel = nil, event: "", &block)
        description = "supports channel trigger "
        description += "on channel #{channel} " if channel
        description += "for event #{event} " unless event.empty?
        description += "with args #{block.source.sub(/.*(?:{|do)\s+\[(.*)\]\s+(?:}|end)/, '\\1')}"

        channel ||= "astro:sun:home:rise#event"
        it description, caller: caller do
          channels = instance_exec(&block)
          triggered = false
          trigger = nil
          channel_config = channels.pop if channels.last.is_a?(Hash)
          channel_config ||= {}
          rule "Execute rule when channel is triggered" do
            channel(*channels, **channel_config)
            run do |e|
              triggered = true
              trigger = e.event
            end
          end
          trigger_channel(channel, event)
          expect(triggered).to be true
          expect(trigger).to eql event
        end
      end

      test_channel_trigger { ["astro:sun:home:rise#event"] }
      test_channel_trigger { ["rise#event", { thing: "astro:sun:home" }] }
      test_channel_trigger { ["rise#event", { thing: things["astro:sun:home"] }] }
      test_channel_trigger { ["rise#event", { thing: things["astro:sun:home"].uid }] }
      test_channel_trigger { ["rise#event", { thing: [things["astro:sun:home"]] }] }
      test_channel_trigger { ["rise#event", { thing: [things["astro:sun:home"].uid] }] }
      test_channel_trigger { [things["astro:sun:home"].channels["rise#event"]] }
      test_channel_trigger { [things["astro:sun:home"].channels["rise#event"].uid] }
      test_channel_trigger { [[things["astro:sun:home"].channels["rise#event"]]] }
      test_channel_trigger { [[things["astro:sun:home"].channels["rise#event"].uid]] }

      test_channel_trigger(event: "START") { ["astro:sun:home:rise#event"] }

      test_channel_trigger("astro:sun:home:rise#event", event: "START") do
        [["rise#event", "set#event"], { thing: "astro:sun:home", triggered: %w[START STOP] }]
      end
      test_channel_trigger("astro:sun:home:set#event", event: "START") do
        [["rise#event", "set#event"], { thing: "astro:sun:home", triggered: %w[START STOP] }]
      end
      test_channel_trigger("astro:sun:home:rise#event", event: "STOP") do
        [["rise#event", "set#event"], { thing: "astro:sun:home", triggered: %w[START STOP] }]
      end
      test_channel_trigger("astro:sun:home:set#event", event: "STOP") do
        [["rise#event", "set#event"], { thing: "astro:sun:home", triggered: %w[START STOP] }]
      end
    end

    describe "#channel_linked" do
      before do
        things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }
      end

      it "triggers" do
        linked_item = linked_thing = nil
        channel_linked do |event|
          linked_item = event.link.item
          linked_thing = event.link.channel_uid.thing
        end

        items.build { string_item "StringItem1", channel: "astro:sun:home:season#name" }

        expect(linked_item).to be StringItem1
        expect(linked_thing).to be things["astro:sun:home"]
      end
    end

    describe "#received_command" do
      before do
        items.build do
          group_item "AlarmModes" do
            number_item "Alarm_Mode", state: 7
            number_item "Alarm_Mode_Other", state: 7
          end
        end
      end

      it "complains about invalid data type" do
        expect { received_command([Alarm_Mode]) { nil } }.to raise_error(ArgumentError)
        expect { received_command("StringItemName") { nil } }.to raise_error(ArgumentError)
        expect { received_command(5) { nil } }.to raise_error(ArgumentError)
        expect do
          received_command(OpenHAB::Core::Things::ThingUID.new("astro:sun:home")) do
            nil
          end
        end.to raise_error(ArgumentError)
      end

      def self.test_command_trigger(item, members: false, command: nil, expect_triggered: true, &block)
        description = "receives command sent to #{item}"
        description += ".members" if members
        description += " with command #{command.inspect}" if command

        it description, caller: caller do
          triggered = false
          item = items[item]
          item = item.members if members
          rule "execute rule when item received command" do
            received_command item, command: command
            run { triggered = true }
          end
          instance_eval(&block)
          expect(triggered).to be expect_triggered
        end
      end

      test_command_trigger("Alarm_Mode") { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode", command: 7) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode", command: 7, expect_triggered: false) { Alarm_Mode << 14 }
      test_command_trigger("Alarm_Mode", command: [7, 14]) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode", command: [7, 14]) { Alarm_Mode << 14 }
      test_command_trigger("Alarm_Mode", command: [7, 14], expect_triggered: false) { Alarm_Mode << 10 }
      test_command_trigger("Alarm_Mode", command: 8..10, expect_triggered: false) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode", command: 4..12) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode",
                           command: ->(t) { (8..10).cover?(t) },
                           expect_triggered: false) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode",
                           command: ->(t) { (4..12).cover?(t) }) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode",
                           command: proc { |t| (8..10).cover?(t) },
                           expect_triggered: false) { Alarm_Mode << 7 }
      test_command_trigger("Alarm_Mode",
                           command: proc { |t| (4..12).cover?(t) }) { Alarm_Mode << 7 }
      test_command_trigger("AlarmModes") { AlarmModes << 7 }
      test_command_trigger("AlarmModes", members: true) { Alarm_Mode << 7 }
      test_command_trigger("AlarmModes", members: true, command: [7, 14]) { Alarm_Mode << 7 }
      test_command_trigger("AlarmModes", members: true, command: [7, 14]) { Alarm_Mode << 14 }
      test_command_trigger("AlarmModes", members: true, command: [7, 14], expect_triggered: false) do
        Alarm_Mode << 10
      end
    end

    describe "#trigger" do
      it "supports an update using a generic trigger" do
        items.build { switch_item "Switch1" }
        triggered = false
        rule "execute rule when item is updated" do
          trigger "core.ItemStateUpdateTrigger", itemName: "Switch1"
          run { triggered = true }
        end
        Switch1.on
        expect(triggered).to be true
      end
    end

    describe "#item_added" do
      it "triggers" do
        new_item = nil
        item_added do |event|
          new_item = event.item
        end

        items.build { switch_item Item1 }

        expect(new_item.name).to eql "Item1"
      end
    end

    describe "#item_removed" do
      it "triggers" do
        removed_item = nil
        item_removed do |event|
          removed_item = event.item
        end

        items.build { switch_item Item1 }
        items.remove(Item1)

        expect(removed_item.name).to eql "Item1"
      end
    end

    describe "#thing_added" do
      it "triggers" do
        new_thing = nil
        thing_added do |event|
          new_thing = event.thing
        end

        things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }

        expect(new_thing.uid).to eql "astro:sun:home"
      end
    end

    describe "#thing_removed" do
      it "triggers" do
        removed_thing = nil
        thing_removed do |event|
          removed_thing = event.thing
        end

        things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }
        things.remove("astro:sun:home")

        expect(removed_thing.uid).to eql "astro:sun:home"
      end
    end

    describe "#updated" do
      it "complains about invalid data type" do
        expect do
          updated([OpenHAB::Core::Things::ThingUID.new("astro:sun:home")]) do
            nil
          end
        end.to raise_error(ArgumentError)
        expect { updated("StringItemName") { nil } }.to raise_error(ArgumentError)
        expect { updated(5) { nil } }.to raise_error(ArgumentError)
      end

      context "with things" do
        let!(:thing) do
          things.build { thing "astro:sun:home", config: { "geolocation" => "0,0" } }
        end

        test_thing_status_trigger(:updated)
        test_thing_status_trigger(:updated, to: :uninitialized)
        test_thing_status_trigger(:updated, to: :unknown, expect_triggered: false)

        it "support ThingUID" do
          triggered = false
          updated things["astro:sun:home"].uid do
            triggered = true
          end
          thing.disable
          expect(triggered).to be true
        end
      end

      context "with items" do
        before do
          items.build do
            group_item "AlarmModes" do
              number_item "Alarm_Mode", state: 7
              number_item "Alarm_Mode_Other", state: 7
            end
          end
        end

        it "triggers when updated" do
          executed = 0
          rule do
            updated Alarm_Mode
            run { executed += 1 }
          end

          Alarm_Mode.update(7)
          expect(executed).to be 1

          Alarm_Mode.update(14)
          expect(executed).to be 2
        end

        it "triggers when updated to a specific value" do
          executed = 0
          rule do
            updated Alarm_Mode, to: 7
            run { executed += 1 }
          end

          Alarm_Mode.update(14)
          expect(executed).to be 0

          Alarm_Mode.update(7)
          expect(executed).to be 1
        end

        it "triggers when updated to a one of several values" do
          executed = 0
          rule do
            updated Alarm_Mode, to: [7, 14]
            run { executed += 1 }
          end

          Alarm_Mode.update(10)
          expect(executed).to be 0

          Alarm_Mode.update(14)
          expect(executed).to be 1

          Alarm_Mode.update(7)
          expect(executed).to be 2
        end

        # This stopped working on OH4-snapshot
        # it "triggers when a group is updated" do
        #   items = []
        #   rule do
        #     updated AlarmModes
        #     run { |event| items << event.item }
        #   end
        #
        #   AlarmModes.update(7)
        #   expect(items).to eql [AlarmModes]
        # end

        it "works with group members" do
          items = []
          rule do
            updated AlarmModes.members
            run { |event| items << event.item }
          end

          Alarm_Mode.update(7)
          expect(items).to eql [Alarm_Mode]
        end

        it "works with group members to specific states" do
          items = []
          rule do
            updated AlarmModes.members, to: [7, 14]
            run { |event| items << event.item }
          end

          Alarm_Mode.update(10)
          expect(items).to be_empty

          Alarm_Mode.update(7)
          expect(items).to eql [Alarm_Mode]

          Alarm_Mode.update(14)
          expect(items).to eql [Alarm_Mode, Alarm_Mode]
        end

        it "triggers when updated to a range of values" do
          executed = 0
          rule do
            updated Alarm_Mode, to: 7..14
            run { executed += 1 }
          end

          Alarm_Mode.update(5)
          expect(executed).to be 0

          Alarm_Mode.update(10)
          expect(executed).to be 1
        end

        it "triggers when updated to a proc" do
          executed = 0
          rule do
            updated Alarm_Mode, to: ->(v) { (7..14).cover?(v) }
            run { executed += 1 }
          end

          Alarm_Mode.update(5)
          expect(executed).to be 0

          Alarm_Mode.update(10)
          expect(executed).to be 1
        end

        it "triggers when a string item is updated against a regex" do
          items.build do
            string_item MyStringItem
          end

          executed = 0
          rule do
            updated MyStringItem, to: /bob/
            run { executed += 1 }
          end

          MyStringItem.update("joe")
          expect(executed).to be 0

          MyStringItem.update("bob")
          expect(executed).to be 1

          MyStringItem.update("plumbob")
          expect(executed).to be 2
        end
      end
    end

    describe "#cron" do
      it "can use cron syntax" do
        attachment = nil
        rule do
          cron (Time.now + 2).strftime("%S %M %H ? * ?"), attach: 1
          run { |event| attachment = event.attachment }
        end
        wait(4.seconds) do
          expect(attachment).to be 1
        end
      end

      it "can use specifiers" do
        cron_trigger = instance_double(OpenHAB::DSL::Rules::Triggers::Cron)
        allow(OpenHAB::DSL::Rules::Triggers::Cron).to receive(:new).and_return(cron_trigger)
        expect(cron_trigger).to receive(:trigger).with(config: { "cronExpression" => "0 5 12 ? * ? *" }, attach: nil)
        rule do
          cron minute: 5, hour: 12
        end
      end

      it "raises ArgumentError about incorrect specifiers" do
        expect do
          cron(made_up: 3, stuff: 5) { nil }
        end.to raise_error(ArgumentError, "unknown keywords: :made_up, :stuff")
      end

      it "tags as Schedule" do
        rule id: "cron_rule" do
          cron (Time.now + 2).strftime("%S %M %H ? * ?"), attach: 1
          run { nil }
        end
        rule = rules["cron_rule"]
        expect(rule).to be_tagged("Schedule")
        trigger = rule.triggers.first
        handler = OpenHAB::Core::Rules.manager.get_module_handler(trigger, rule.uid)
        expect(handler.getTemporalAdjuster).not_to be_nil
      end
    end

    describe "#at" do
      it "works" do
        items.build { date_time_item MyDateTimeItem }

        triggered = false
        rule do
          at MyDateTimeItem
          run { triggered = true }
        end
        MyDateTimeItem.update(Time.now + 2)
        wait(4.seconds) do
          expect(triggered).to be true
        end
      end

      it "tags as Schedule" do
        items.build { date_time_item MyDateTimeItem }

        rule id: "at_rule" do
          at MyDateTimeItem
          run { nil }
        end
        rule = rules["at_rule"]
        expect(rule).to be_tagged("Schedule")
        trigger = rule.triggers.first
        handler = OpenHAB::Core::Rules.manager.get_module_handler(trigger, rule.uid)
        expect(handler.getTemporalAdjuster).not_to be_nil
      end
    end

    describe "#every" do
      def self.generate(name, cron_expression, *every_args, attach: nil, **kwargs)
        it name, caller: caller do
          rspec = self
          executed = false
          rule do
            rspec.expect(self).to rspec.receive(:cron).with(cron_expression, attach: attach)
            every(*every_args, attach: attach, **kwargs)
            executed = true
          end
          expect(executed).to be true
        end
      end

      generate("uses cron for :seconds", "* * * ? * ? *", :second)
      generate("passes through attachment", "* * * ? * ? *", :second, attach: 1)
      generate("can use durations", "*/5 * * ? * ? *", 5.seconds)
      generate("can use MonthDay and LocalTime", "0 0 12 17 11 ? *", MonthDay.parse("11-17"),
               at: LocalTime.parse("12:00"))
      generate("can use MonthDay as a string", "0 0 12 17 11 ? *", "11-17", at: LocalTime.parse("12:00"))
      generate("can use LocalTime a string", "0 0 12 17 11 ? *", MonthDay.parse("11-17"), at: "12:00")

      it "supports dynamic `at`" do
        items.build { date_time_item MyDateTimeItem }

        triggered = false
        every(:day, id: "dynamic_at_rule", at: MyDateTimeItem) { triggered = true }

        rule = rules["dynamic_at_rule"]
        expect(rule).to be_tagged("Schedule")
        trigger = rule.triggers.first
        handler = OpenHAB::Core::Rules.manager.get_module_handler(trigger, rule.uid)
        expect(handler.getTemporalAdjuster).not_to be_nil

        MyDateTimeItem.update(Time.now + 2 - 2.days)
        wait(4.seconds) do
          expect(triggered).to be true
        end
      end

      it "complains about dynamic at that's not daily" do
        items.build { date_time_item MyDateTimeItem }

        expect { every :month, at: MyDateTimeItem }.to raise_error(ArgumentError)
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    describe "#watch" do
      #
      # NOTE: OH4's watch service suppresses successive file change events
      # and change the notification kind. When a DELETE - CREATE sequence of events actually happened,
      # OH4 will send a MODIFY event instead.
      #
      # Because of this, avoid using the same file name in different tests
      # because when it's deleted at the end of one test and re-created in the next test,
      # it will result in a MODIFY event instead of CREATE. This may trip up the test if it's
      # specifically expecting a CREATE event.
      #
      # `test_file` returns a random name that should be unique
      #

      before :all do # rubocop:disable RSpec/BeforeAfterAll
        OpenHAB::Log.logger("org.openhab.core.internal.service.WatchServiceImpl").level = :trace
        sleep 0.05
      end

      after :all do # rubocop:disable RSpec/BeforeAfterAll
        OpenHAB::Log.logger("org.openhab.core.internal.service.WatchServiceImpl").level = :default
      end

      around do |example|
        Dir.mktmpdir("openhab-rspec") do |dir|
          @temp_dir = dir
          example.call
        end
      end

      let(:config_folder) { OpenHAB::Core.config_folder }
      let(:test_file) { "rspec-test-#{SecureRandom.uuid}" }

      #
      # Sets up and performs the test for watch trigger
      #
      # @param [String] filename The name of the file to create. It can be a plain name without path,
      #   or an absolute path. When it's a plain name, the file will be created inside @temp_dir
      #   If an absolute path is provided and the directory doesn't exist, attempt to create
      #   it non-recursively (i.e. only if the directory's parent already existed), and clean it up
      #   afterwards.
      # @param [Array<String, Hash>] watch_args The arguments for the watch trigger. The first
      #   argument is a string containing the directory to wath. The second argument is a hash
      #   containing kwargs for `watch`
      # @param [Boolean] expected Whether we expected the watch trigger to be executed
      # @param [Array<:created, :modified, :deleted>,nil] check The type of triggers to check
      #
      def test_it(filename, watch_args:, expected: true, check: nil)
        filename = Pathname.new(filename) unless filename.is_a?(Pathname)
        raise "the path in filename must be absolute" if filename.basename != filename && !filename.absolute?

        temp_path = Pathname.new(@temp_dir)

        logger.trace("test_it: #{filename}, watch_args: #{watch_args}, expected: #{expected}, check: #{check}")

        path = type = nil
        watch_path, config = *watch_args
        config ||= {}
        rule do
          watch(watch_path, **config)
          run do |event|
            path = event.path
            type = event.type
          end
        end

        existing_dir = nil
        created_subdir = filename.absolute? && !filename.dirname.exist? && filename.dirname
        if created_subdir
          # after setting up the watch rule, create missing subdirectories so we can create our test file

          filename.dirname.ascend { |dir| break existing_dir = dir if dir.directory? }
          raise "#{filename} doesn't contain any existing directory" unless existing_dir

          logger.trace("Creating directory: #{created_subdir}")

          FileUtils.mkdir_p(created_subdir)
          expect(filename.dirname).to be_directory
          logger.trace("Directory created: #{created_subdir}")
        else
          filename = temp_path / filename
        end

        # Sometimes OH's watch service is not ready right away
        # either after the creation of a subdirectory above (OH3), or right after registration (OH4)
        sleep 0.1

        expect(filename.exist?).to be false

        logger.debug("Creating file #{filename}")
        File.open(filename, "wb") { nil }
        expect(filename.exist?).to be true
        expected = false unless check.nil?
        if expected || check&.include?(:created)
          wait do
            expect(path).to eql filename
            expect(type).to be :created
          end
        else
          sleep 1.2
          expect(path).to be_nil
          expect(type).to be_nil
        end

        return if check.nil?

        path = nil
        type = nil
        logger.debug("Modifying file #{filename}")
        File.write(filename, "bye")
        if check.include?(:modified)
          wait do
            expect(path).to eql filename
            expect(type).to be :modified
          end
        else
          sleep 1.2
          expect(path).to be_nil
          expect(type).to be_nil
        end

        path = nil
        type = nil
        logger.debug("Deleting file #{filename}")
        File.unlink(filename)
        if check.include?(:deleted)
          wait do
            expect(path).to eql filename
            expect(type).to be :deleted
          end
        else
          sleep 1.2
          expect(path).to be_nil
          expect(type).to be_nil
        end
      ensure
        FileUtils.rm(filename) if filename.exist?
        logger.trace("File deleted: #{filename}")
        if existing_dir
          created_subdir&.ascend do |dir|
            break if dir == existing_dir || !dir.directory?

            Dir.rmdir(dir)
            logger.trace("Directory deleted: '#{dir}'")
          end
        end
      end

      describe "non-recursively" do
        let(:recursive_watch) { false }

        it "works" do
          test_it(test_file, check: %i[created modified deleted], watch_args: [@temp_dir])
        end

        it "supports globs" do
          test_it("#{test_file}.erb", watch_args: [@temp_dir, { glob: "*.erb", for: :created }])
        end

        it "supports globs in path" do
          test_it("#{test_file}.erb", watch_args: ["#{@temp_dir}/*.erb", { for: :created }])
        end

        it "filters files not matching the glob" do
          test_it("#{test_file}.txt", expected: false, watch_args: [@temp_dir, { glob: "*.erb" }])
        end

        it "filters files not matching the glob in the path" do
          test_it("#{test_file}.txt", expected: false, watch_args: ["#{@temp_dir}/*.erb"])
        end

        it "supports watching a single file" do
          test_it(test_file, watch_args: ["#{@temp_dir}/#{test_file}"])
        end

        it "ignores a non-matching file" do
          test_it("#{test_file}.txt", expected: false, watch_args: ["#{@temp_dir}/file"])
        end

        it "can filter by event type :created" do
          test_it(test_file, check: [:created], watch_args: [@temp_dir, { for: :created }])
        end

        it "can filter by event type :modified" do
          test_it(test_file, check: [:modified], watch_args: [@temp_dir, { for: :modified }])
        end

        it "can filter by event type :deleted" do
          test_it(test_file, check: [:deleted], watch_args: [@temp_dir, { for: :deleted }])
        end

        it "can filter by event types :modified or :deleted" do
          test_it(test_file, check: %i[modified deleted], watch_args: [@temp_dir, { for: %i[modified deleted] }])
        end

        it "can filter by event types :modified or :created" do
          test_it(test_file, check: %i[modified created], watch_args: [@temp_dir, { for: %i[modified created] }])
        end

        it "uses the built in configWatcher to monitor inside openHAB config folder" do
          expect(OpenHAB::DSL::Rules::Triggers::WatchHandler.factory).not_to receive(:create_watch_service)
          test_it(config_folder / "scripts" / test_file, watch_args: [config_folder / "scripts"])
        end

        it "doesn't monitor changes inside subdirectories" do
          test_it(config_folder / "tmp" / test_file, expected: false,
                                                     watch_args: [config_folder, { glob: test_file, for: :created }])
        end
      end

      describe "recursively" do
        let(:recursive_watch) { true }

        it "can watch for files several levels deep" do
          file = config_folder / "tmp/a/b/c" / test_file
          test_it(file, watch_args: [config_folder / "**", { for: :created }])
        end

        it "can watch for files in the main directory" do
          test_it(config_folder / test_file, watch_args: [config_folder / "**", { for: :created }])
        end

        it "can watch the parent directory when given a non existent path" do
          # ensure this subdirectory doesn't exist
          subdir = config_folder / "nonexistent"
          FileUtils.rm_rf(subdir, secure: true)
          expect(subdir.exist?).to be false

          test_it(subdir / "#{test_file}.x", watch_args: [subdir / "#{test_file}.x", { for: :created }])
        end

        it "supports complex patterns" do
          file = config_folder / "tmp/foo/bar/baz/blob.magoo"
          test_it(file, watch_args: [config_folder / "{tmp,xyz}/[a-g]oo/bar/*/*.magoo"])
        end

        describe "using glob option" do
          it "works" do
            file = config_folder / "tmp" / "#{test_file}.x"
            test_it(file, watch_args: [config_folder, { glob: "**.x", for: :created }])
          end

          it "supports relative subdirectory" do
            file = config_folder / "tmp" / "#{test_file}.x"
            test_it(file, watch_args: [config_folder, { glob: "tmp/*.x", for: :created }])
          end

          it "supports absolute path" do
            file = config_folder / "tmp" / "#{test_file}.x"
            test_it(file, watch_args: [config_folder, { glob: config_folder / "**/*.x", for: :created }])
          end
        end
      end
    end
    # rubocop:enable RSpec/InstanceVariable
  end

  describe "execution blocks" do
    describe "#run" do
      it "can call top level methods" do
        def outer_function
          logger.info("Outer function called")
        end
        rule do
          on_load
          run { outer_function }
        end
        expect(spec_log_lines).to include(include("Outer function called"))
      end

      context "without exception propagation" do
        self.propagate_exceptions = false

        it "logs errors" do
          rule do
            on_load
            run { raise "failure!" }
          end
          expect(spec_log_lines).to include(include("failure! (RuntimeError)"))
          expect(spec_log_lines).to include(match(%r{rules/builder_spec\.rb:(?:\d+):in `block}))
        end

        it "logs java exceptions" do
          rule do
            on_load
            run { java.lang.Integer.parse_int("k") }
          end
          expect(spec_log_lines).to include(include("Java::JavaLang::NumberFormatException"))
          expect(spec_log_lines).to include(match(/RUBY.*builder_spec\.rb/))
        end
      end

      def self.test_event(trigger)
        it "is passed `event` from #{trigger}", caller: caller do
          items.build { switch_item "Switch1" }
          item = nil
          rule do
            send(trigger, Switch1)
            run { |event| item = event.item }
          end
          Switch1.on
          expect(item).to be Switch1
        end
      end

      test_event(:changed)
      test_event(:updated)

      it "runs multiple blocks" do
        ran = 0
        rule do
          on_load
          run { ran += 1 }
          run { ran += 1 }
          run { ran += 1 }
        end
        expect(ran).to be 3
      end
    end

    describe "#delay" do
      it "works" do
        executed = 0
        rule do
          on_load
          run { executed += 1 }
          delay 5.seconds
          run { executed += 1 }
        end
        expect(executed).to be 1
        time_travel_and_execute_timers(10.seconds)
        expect(executed).to be 2
      end
    end

    describe "triggered" do
      before do
        items.build do
          group_item "Switches" do
            switch_item "Switch1", state: OFF
            switch_item "Switch2", state: OFF
          end
        end
      end

      it "works" do
        item = nil
        rule do
          changed Switch1
          triggered { |i| item = i }
        end

        Switch1.on
        expect(item).to be Switch1
      end

      it "triggers the item from the group" do
        item = nil
        rule do
          changed Switches.members
          triggered { |i| item = i }
        end

        Switch1.on
        expect(item).to be Switch1
      end

      it "works with the & operator" do
        rule do
          changed Switches.members
          triggered(&:off)
        end

        Switch1.on
        expect(Switch1).to be_off
      end

      it "supports multiple execution blocks" do
        item = nil
        rule "turn a switch off five seconds after turning it on" do
          changed Switches.members, to: ON
          delay 5.seconds
          triggered(&:off)
          triggered { |i| item = i }
        end

        Switch1.on
        expect(item).to be_nil

        time_travel_and_execute_timers(10.seconds)
        expect(item).to be Switch1
        expect(Switch1).to be_off
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    context "with guards" do
      describe "#only_if" do
        def run_rule
          rule do
            on_load
            run { @ran = :run }
            otherwise { @ran = :otherwise }
            only_if { @condition }
          end
        end

        it "executes run blocks if only_if is true" do
          @condition = true
          run_rule
          expect(@ran).to be :run
        end

        it "executes otherwise blocks if only_if is false" do
          @condition = false
          run_rule
          expect(@ran).to be :otherwise
        end

        it "supports multiple only_if blocks" do
          ran = false
          rule do
            on_load
            run { ran = true }
            only_if { true }
            only_if { true }
          end
          expect(ran).to be true
        end

        it "supports multiple only_if blocks but doesn't run if any are false" do
          ran = false
          rule do
            on_load
            run { ran = true }
            only_if { true }
            only_if { false }
          end
          expect(ran).to be false
        end
      end

      describe "#not_if" do
        def run_rule
          rule do
            on_load
            run { @ran = :run }
            otherwise { @ran = :otherwise }
            not_if { @condition }
          end
        end

        it "executes run blocks if not_if is false" do
          @condition = false
          run_rule
          expect(@ran).to be :run
        end

        it "executes otherwise blocks if not_if is true" do
          @condition = true
          run_rule
          expect(@ran).to be :otherwise
        end

        it "supports multiple not_if blocks" do
          ran = false
          rule do
            on_load
            run { ran = true }
            not_if { false }
            not_if { false }
          end
          expect(ran).to be true
        end

        it "supports multiple only_if blocks but doesn't run if any are true" do
          ran = false
          rule do
            on_load
            run { ran = true }
            not_if { true }
            not_if { false }
          end
          expect(ran).to be false
        end
      end

      def self.test_combo(only_if_value, not_if_value, result)
        it "#{result ? "runs" : "doesn't run"} for only_if #{only_if_value} and #{not_if_value}", caller: caller do
          ran = false
          rule do
            on_load
            run { ran = true }
            only_if { only_if_value }
            not_if { not_if_value }
          end
          expect(ran).to be result
        end
      end

      test_combo(true, false, true)
      test_combo(false, false, false)
      test_combo(false, true, false)
      test_combo(true, true, false)

      it "has access to event info" do
        items.build { switch_item "Switch1" }
        item = nil
        this = nil
        rule do
          changed Switch1
          run { nil }
          only_if do |event|
            item = event.item
            this = self
          end
        end
        Switch1.on
        expect(item).to be Switch1
        expect(this).to be self
      end

      describe "#between" do # rubocop:disable RSpec/EmptyExampleGroup
        def self.test_it(range, expected)
          it "works with #{range.inspect} (#{range.begin.class})", caller: caller do
            ran = false
            rule do
              on_load
              between range
              run { ran = true }
            end
            expect(ran).to be expected
          end
        end

        test_it(5.minutes.ago.to_local_time..5.minutes.from_now.to_local_time, true)
        test_it(5.minutes.ago.to_local_time.to_s..5.minutes.from_now.to_local_time.to_s, true)
        test_it(10.minutes.ago..5.minutes.ago, false)
        test_it(1.day.ago.to_local_date..1.day.from_now.to_local_date, true)
      end

      describe "Debounce Guards" do
        before { Timecop.freeze(Time.at(0)) }

        let(:item) { items.build { number_item "Item1" } }

        def test_debouncing(type, arg, triggers, expected)
          executed = []
          rule do
            updated Item1
            send(type, arg)
            run { |event| executed << event.state.to_i }
          end

          last_trigger = nil
          last_executed = nil
          triggers.chars.each_with_index do |trigger, i|
            item.update(last_trigger = i) if trigger == "X"
            execute_timers
            if expected[i] == "X"
              expect(executed.last).to eq last_trigger
              last_executed = last_trigger
            else
              expect(executed.last).to eq last_executed
            end
            Timecop.freeze(1)
          end
        end

        describe "#debounce_for" do
          it "works" do
            #                     1    1    2    2    3    3    4    4
            #           0    5    0    5    0    5    0    5    0    5
            triggers = "X.X...X...X..XX.X.X....X.XXXXXXXXXXX....X....."
            expected = "|......................X.|..............X....."
            test_debouncing(:debounce_for, 5.seconds, triggers, expected)
          end

          it "supports ranges" do
            #                     1    1    2    2    3    3    4    4
            #           0    5    0    5    0    5    0    5    0    5
            trigger = "X.X...X...X..XX.X.X....X.XXXXXXXXXXX....X....."
            tests = {
              5..5 => "|....X|....X.|....X....|....X|....X|....X....X",
              5..6 => "|.....X...|.....X.|....X.|.....X|.....X.|....X",
              5..7 => "|......X..|......X|....X.|......X|......X.....",
              5..8 => "|.......X.|.......X....|.......X|.......X.....",
              5..20 => "|...................X..|................X....."
            }.transform_keys { |k| Range.new(k.begin.seconds, k.end.seconds) }

            tests.each do |arg, expected|
              test_debouncing(:debounce_for, arg, trigger, expected)
            end
          end
        end

        describe "#throttle_for" do
          it "works" do
            #                     1    1    2    2    3    3    4    4
            #           0    5    0    5    0    5    0    5    0    5
            triggers = "X.X...X...X..XX.X.X....X.XXXXXXXXXXX....X....."
            expected = "|....X|....X.|....X....|....X|....X|....X....."
            test_debouncing(:throttle_for, 5.seconds, triggers, expected)
          end
        end

        describe "#only_every" do
          it "works" do
            #                     1    1    2    2    3    3    4    4
            #           0    5    0    5    0    5    0    5    0    5
            triggers = "X.X...X...X..XX.X.X....X.XXXXXXXXXXX....X....."
            expected = "X.....X......X....X....X....X....X......X....."
            test_debouncing(:only_every, 5.seconds, triggers, expected)
          end

          it "accepts symbolic duration" do
            def test_symbol(symbol)
              rule do
                updated Item1
                only_every symbol
                run { nil }
              end
            end

            %i[second minute hour day].each do |sym|
              expect { test_symbol sym }.not_to raise_exception
            end
          end
        end
      end
    end
    # rubocop:enable RSpec/InstanceVariable
  end

  describe "#description" do
    it "works" do
      rule id: "test_rule" do
        description "Rule Description"
        every :day
        run { nil }
      end
      expect($rules.get("test_rule").description).to eql "Rule Description"
    end
  end

  describe "#tags" do
    it "works" do
      rule id: "test_rule" do
        tags "tag1", "tag2", Semantics::LivingRoom
        every :day
        run { nil }
      end
      expect($rules.get("test_rule").tags).to match_array(%w[tag1 tag2 LivingRoom Schedule])
    end

    it "works with a single tag" do
      rule id: "test_rule" do
        tags "tag1"
        every :day
        run { nil }
      end
      expect($rules.get("test_rule").tags).to match_array(%w[tag1 Schedule])
    end

    it "creates a scene" do
      rule id: "test_scene" do
        tags :Scene
        run { nil }
      end

      expect(rules.scenes["test_scene"]).not_to be_nil
    end
  end

  describe "attachments" do
    let(:item) { items.build { switch_item "Item1" } }
    let(:thing) do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      end
    end

    def self.test_it(*trigger, &block)
      it "passes through attachment for #{trigger.first}", caller: caller do
        attachment = nil
        trigger[1] = binding.eval(trigger[1]) if trigger.length == 2 # rubocop:disable Security/Eval
        kwargs = {}
        kwargs = trigger.pop if trigger.length == 3
        kwargs[:attach] = 1
        rule do
          send(*trigger, **kwargs)
          run { |event| attachment = event.attachment }
        end
        instance_eval(&block) if block
        expect(attachment).to be 1
      end
    end

    test_it(:changed, "item") { item.on }
    test_it(:updated, "item") { item.on }
    test_it(:received_command, "item") { item.on }
    test_it(:channel, "astro:sun:home:rise#event".inspect) do
      thing
      trigger_channel("astro:sun:home:rise#event")
    end
    test_it(:on_load)
    test_it(:trigger, "core.ItemStateUpdateTrigger", itemName: "Item1") { item.on }

    it "passes through attachment for watch" do
      Dir.mktmpdir("openhab-rspec") do |temp_dir|
        attachment = nil
        rule do
          watch temp_dir, attach: 1
          run { |event| attachment = event.attachment }
        end

        sleep 0.1 # Wait for the watch service to be ready

        file = File.join(temp_dir, "file")
        File.write(file, "hi")
        wait do
          expect(attachment).to be 1
        end
      end
    end
  end

  describe "#dependencies" do
    it "gathers dependencies from all triggers" do
      items.build do
        number_item Item1
        number_item Item2
        number_item Item3
        switch_item Item4
      end

      r = nil
      rule do |rule|
        r = rule
        changed Item1, Item2
        updated Item3
        received_command Item4
      end

      expect(r.dependencies).to eql [Item1, Item2, Item3]
      expect(r.dependencies(:received_command)).to eql [Item4]
      expect(r.dependencies(:updated)).to eql [Item3]
    end
  end
end
