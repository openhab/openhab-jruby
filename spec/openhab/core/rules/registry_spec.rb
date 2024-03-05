# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Rules::Registry do
  describe "#remove" do
    it "works" do
      my_rule = rule do
        every :day
        run { nil }
      end

      expect(rules).to have_key(my_rule.uid)
      rules.remove(my_rule)
      expect(rules).not_to have_key(my_rule.uid)
    end

    it "can re-add a rule with the same id after it has been removed" do
      rule id: "myid" do
        every :day
        run { nil }
      end

      rules.remove("myid")
      expect(rules).not_to have_key("myid")

      rule id: "myid" do
        every :day
        run { nil }
      end

      expect(rules).to have_key("myid")
    end

    it "returns nil if the rule is not found" do
      expect(rules.remove("nonexistent")).to be_nil
    end

    it "cleans up timers for a duration condition when the rule is removed" do
      items.build { switch_item "Item1" }
      my_rule = rule do
        changed Item1, for: 5.minutes
        run { nil }
      end

      expect(OpenHAB::DSL::TimerManager.instance.instance_variable_get(:@timers).size).to be 0
      Item1.on
      expect(OpenHAB::DSL::TimerManager.instance.instance_variable_get(:@timers).size).to be 1
      rules.remove(my_rule)
      expect(OpenHAB::DSL::TimerManager.instance.instance_variable_get(:@timers).size).to be 0
    end
  end
end
