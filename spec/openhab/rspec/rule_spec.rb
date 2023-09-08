# frozen_string_literal: true

RSpec.describe "rules" do
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
