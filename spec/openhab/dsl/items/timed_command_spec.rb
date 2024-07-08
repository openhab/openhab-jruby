# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Items::TimedCommand do
  let(:item) { items.build { number_item "item", state: 0 } }

  it "has an implicit timer when sending commands" do
    item.command(70, for: 5.seconds)
    expect(item.state).to eq 70
    time_travel_and_execute_timers(10.seconds)
    expect(item.state).to eq 0
  end

  it "can set the expire state" do
    item.command(70, for: 5.seconds, on_expire: 9)
    expect(item.state).to eq 70
    time_travel_and_execute_timers(10.seconds)
    expect(item.state).to eq 9
  end

  it "handles re-entrancy" do
    item.command(7, for: 5.seconds)
    expect(item.state).to eq 7
    time_travel_and_execute_timers(3.seconds)
    expect(item.state).to eq 7
    item.command(7, for: 5.seconds)
    expect(item.state).to eq 7
    time_travel_and_execute_timers(3.seconds)
    # still 7; the original timer was extended
    expect(item.state).to eq 7
    time_travel_and_execute_timers(3.seconds)
    expect(item.state).to eq 0
  end

  it "returns `self` (wrapped in a proxy)" do
    expect(item.command(7, for: 1.seconds)).to be item
  end

  context "with `only_when_ensured` option" do
    it "can activate only when ensured" do
      commanded = false
      received_command(item) { commanded = true }

      if commanded # This won't execute because it's only for self documentation
        # First check our assumptions of the behavior without `only_when_ensured`
        # Possibly unnecessary because such behavior is already tested in other specs
        # but nice to have here for clarity
        #
        # ********
        # first without ensure
        item.update 7
        item.command(7, for: 1.second, on_expire: 0)
        expect(commanded).to be true

        commanded = false
        time_travel_and_execute_timers(2.seconds)
        expect(commanded).to be true
        expect(item.state).to eq 0

        # ********
        # now with ensure (but still without `only_when_ensured`)
        item.update(7)
        commanded = false
        item.ensure.command(7, for: 1.second, on_expire: 0)
        expect(commanded).to be false

        commanded = false

        # the timed command still executes even though the command was ensured
        time_travel_and_execute_timers(2.seconds)
        expect(commanded).to be true
        expect(item.state).to eq 0
      end

      # ********
      # now try it with `only_when_ensured`
      item.update(7)
      commanded = false
      item.command(7, for: 1.second, on_expire: 0, only_when_ensured: true)
      expect(commanded).to be false

      time_travel_and_execute_timers(2.seconds)
      expect(commanded).to be false
      # The difference is here: the timer didn't even start, so the state didn't change to `on_expire` state
      expect(item.state).to eq 7

      # ********
      # calling ensure explicitly should still work
      item.update(7) # not necessary but for clarity
      commanded = false
      item.ensure.command(7, for: 1.second, on_expire: 0, only_when_ensured: true)
      expect(commanded).to be false

      time_travel_and_execute_timers(2.seconds)
      expect(commanded).to be false
      # The difference is here: the timer didn't even start, so the state didn't change to `on_expire` state
      expect(item.state).to eq 7
    end

    it "returns self when the timer was started" do
      item.update(0)
      result = item.command(7, for: 1.second, only_when_ensured: true)
      expect(result).to be item
    end

    it "returns nil when the timer was not started" do
      item.update(0)
      result = item.command(0, for: 1.second, only_when_ensured: true)
      expect(result).to be_nil
    end
  end

  describe "#ensure_timed_commands!" do
    around do |example|
      ensure_timed_commands!
      example.run
    ensure
      ensure_timed_commands!(default: false)
    end

    it "makes `only_when_ensured` defaults to true for all timed commands" do
      commanded = false
      received_command(item) { commanded = true }

      item.update(7)
      # only_when_ensured is not specified in this call, but it should now defaults to true
      item.command(7, for: 1.second, on_expire: 0)
      expect(commanded).to be false

      time_travel_and_execute_timers(2.seconds)
      expect(commanded).to be false
      # check that the timer didn't even start, so the state didn't change to `on_expire` state
      expect(item.state).to eq 7
    end
  end

  describe "#ensure_timed_commands" do
    it "only takes effect inside the block" do
      commanded = false
      received_command(item) { commanded = true }

      ensure_timed_commands do
        item.update(7)
        # only_when_ensured is not specified in this call, but it should now defaults to true
        item.command(7, for: 1.second, on_expire: 0)
        expect(commanded).to be false

        time_travel_and_execute_timers(2.seconds)
        expect(commanded).to be false
        # check that the timer didn't even start, so the state didn't change to `on_expire` state
        expect(item.state).to eq 7
      end

      # After the block, it shoult not default to true anymore
      item.update(7)
      commanded = false
      item.command(7, for: 1.second, on_expire: 0)
      expect(commanded).to be true

      time_travel_and_execute_timers(2.seconds)
      expect(item.state).to eq 0
    end
  end

  context "with SwitchItem" do
    let(:item) { items.build { switch_item "Switch1" } }

    def self.test_it(initial_state, command)
      it "expires to the inverse of #{command} even when starting with #{initial_state}", caller: caller do
        item.update(initial_state)
        item.command(command, for: 5.seconds)
        expect(item.state).to eq command
        time_travel_and_execute_timers(10.seconds)
        expect(item.state).to eq !command
      end
    end

    test_it(ON, ON)
    test_it(OFF, OFF)
    test_it(OFF, ON)
    test_it(ON, OFF)

    it "allows timers with command helper methods" do
      item.on(for: 5.seconds)
      expect(item).to be_on
      time_travel_and_execute_timers(10.seconds)
      expect(item).to be_off
    end
  end

  it "accepts expire blocks" do
    executed = false
    item.command(5, for: 5.seconds) do |timed_command|
      executed = true
      expect(timed_command).to be_expired
    end
    expect(executed).to be false
    time_travel_and_execute_timers(10.seconds)
    expect(executed).to be true
  end

  it "cancels implicit timers when item state changes before timer expires" do
    item.command(5, for: 5.seconds)
    expect(item.state).to eq 5
    item.update(6)
    expect(item.state).to eq 6
    time_travel_and_execute_timers(10.seconds)
    # didn't revert
    expect(item.state).to eq 6
  end

  it "doesn't cancel implicit timers when item receives update of the same state" do
    item.command(5, for: 5.seconds)
    expect(item.state).to eq 5
    item.update(5)
    time_travel_and_execute_timers(10.seconds)
    expect(item.state).to eq 0
  end

  it "cancels implicit timers when item receives another command of the same value" do
    expect(item.state).to eq 0
    item.command(5, for: 5.seconds)
    expect(item.state).to eq 5
    item << 5
    time_travel_and_execute_timers(10.seconds)
    # didn't revert
    expect(item.state).to eq 5
  end

  it "cancels implicit timers when item receives another command of a different value" do
    expect(item.state).to eq 0
    item.command(5, for: 5.seconds)
    expect(item.state).to eq 5
    item << 6
    time_travel_and_execute_timers(10.seconds)
    # didn't revert
    expect(item.state).to eq 6
  end

  it "calls the block even if the timer was canceled" do
    executed = false
    item.command(5, for: 5.seconds) do |timed_command|
      executed = true
      expect(timed_command).to be_cancelled
    end
    expect(item.state).to eq 5
    expect(executed).to be false
    item << 6
    expect(item.state).to eq 6
    expect(executed).to be true
    executed = false
    time_travel_and_execute_timers(10.seconds)
    expect(executed).to be false
    # didn't revert
    expect(item.state).to eq 6
  end

  it "works with ensure" do
    item.ensure.command(5, for: 5.seconds, on_expire: 20)
    expect(item.state).to eq 5
    time_travel_and_execute_timers(10.seconds)
    expect(item.state).to eq 20
  end

  it "updates the duration of the implicit timer" do
    item.ensure.command(5, for: 3.seconds)
    item.ensure.command(6, for: 10.seconds)
    expect(item.state).to eq 6
    time_travel_and_execute_timers(8.seconds)
    expect(item.state).to eq 6
    time_travel_and_execute_timers(8.seconds)
    expect(item.state).to eq 0
  end

  it "updates the on_expire value" do
    item.command(5, for: 3.seconds, on_expire: 7)
    item.command(6, for: 10.seconds, on_expire: 8)
    expect(item.state).to eq 6
    time_travel_and_execute_timers(8.seconds)
    expect(item.state).to eq 6
    time_travel_and_execute_timers(8.seconds)
    expect(item.state).to eq 8
  end

  it "can reset to NULL" do
    item.update(NULL)
    item.command(5, for: 3.seconds)
    expect(item.state).to eq 5
    time_travel_and_execute_timers(5.seconds)
    expect(item).to be_null
  end

  it "works with non-auto-updated items" do
    manualitem = items.build { switch_item "Switch1", autoupdate: false }
    manualitem.update(OFF)
    manualitem.command(ON, for: 3.seconds)
    manualitem.update(ON)
    manualitem.metadata[:autoupdate] = true
    time_travel_and_execute_timers(5.seconds)
    expect(manualitem.state).to eq OFF
  end

  it "works with GroupItem" do
    items.build { group_item "Group1", type: "Switch", autoupdate: true }
    Group1.update(OFF)
    Group1.command(ON, for: 1.second)
    expect(Group1).to be_on
    time_travel_and_execute_timers(2.seconds)
    expect(Group1).to be_off
  end

  context "with Enumerable" do
    before do
      items.build do
        switch_item Switch1, state: OFF
        switch_item Switch2, state: OFF
      end
    end

    it "works" do
      [Switch1, Switch2].command(ON, for: 1.second)
      expect(Switch1).to be_on
      expect(Switch2).to be_on
      time_travel_and_execute_timers(2.seconds)
      expect(Switch1).to be_off
      expect(Switch2).to be_off
    end

    it "each member has its own timer" do
      [Switch1, Switch2].command(ON, for: 1.second)
      Switch1.on
      time_travel_and_execute_timers(2.seconds)
      expect(Switch1).to be_on
      expect(Switch2).to be_off
    end
  end
end
