# frozen_string_literal: true

RSpec.describe "rules" do
  context "with real timers" do
    self.mock_timers = false

    it "uses the real scheduler for time-based rule triggers" do
      built_rule = every(:day) { nil }
      trigger = built_rule.triggers.first
      handler = OpenHAB::Core::Rules.manager.get_module_handler_factory(trigger.type_uid)
                                    .get_handler(trigger, built_rule.uid)
      handler.class.field_reader :schedule
      expect(handler.schedule).not_to be_nil
      expect(handler.schedule).not_to be_a(OpenHAB::RSpec::Mocks::CronScheduler::Schedule)
    end
  end

  context "with in-spec created rules" do
    # Has to be in before/after(:all) so that the top-level after hook has run;
    # this example group explicitly has a single spec
    # rubocop:disable RSpec/BeforeAfterAll
    before(:all) do
      rule id: "out-of-spec-rule" do
        every :day
        run { nil }
      end
    end

    after(:all) do
      expect($rules.get("out-of-spec-rule")).not_to be_nil
      rules.remove("out-of-spec-rule")
      expect($rules.get("out-of-spec-rule")).to be_nil
      expect($rules.get("in-spec-rule")).to be_nil
    end
    # rubocop:enable RSpec/BeforeAfterAll, RSpec/ExpectInHook

    it "cleans up all rules created in a spec (but not rules created outside of it)" do
      rule id: "in-spec-rule" do
        every :day
        run { nil }
      end
    end
  end

  context "with an item" do
    before do
      items.build { switch_item "MySwitch" }
    end

    it "mocks time scheduling while retaining other triggers and manual execution" do
      items.build { date_time_item "ScheduledTime", state: Time.now + 60 }
      executed = 0
      built_rule = rule do
        cron "* * * ? * ?"
        every :second
        every :day, at: "12:00"
        trigger "timer.TimeOfDayTrigger", time: "12:00"
        at ScheduledTime
        every :day, at: ScheduledTime
        changed MySwitch
        run { executed += 1 }
      end

      ScheduledTime.update(Time.now + 120)
      built_rule.triggers.to_a.first(6).each do |trigger|
        handler = OpenHAB::Core::Rules.manager.get_module_handler_factory(trigger.type_uid)
                                      .get_handler(trigger, built_rule.uid)
        handler.class.field_reader :schedule
        expect(handler.schedule).to be_a(OpenHAB::RSpec::Mocks::CronScheduler::Schedule)
      end

      expect(built_rule).to be_enabled
      MySwitch.update(ON)
      expect(executed).to eq 1
      built_rule.trigger
      expect(executed).to eq 2
    end

    it "trigger on changed" do
      executed = 0
      changed(MySwitch) { executed += 1 }
      MySwitch.update(ON)
      MySwitch.update(ON)
      expect(executed).to eq 1
    end

    it "trigger on updated" do
      executed = 0
      updated(MySwitch) { executed += 1 }
      MySwitch.update(ON)
      MySwitch.update(ON)
      expect(executed).to eq 2
    end

    it "trigger on command" do
      executed = 0
      received_command(MySwitch) { executed += 1 }
      MySwitch.on
      MySwitch.update(ON)
      expect(executed).to eq 1
    end
  end
end
