# frozen_string_literal: true

RSpec.describe "debouncer isolation" do
  # Populate the shared cache before the per-example reset hook runs.
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    debounce(for: 1.hour, leading: true, id: "rspec-debouncer-isolation") { nil }
  end

  after(:all) do
    OpenHAB::DSL.debouncers.remove("rspec-debouncer-isolation")
  end
  # rubocop:enable RSpec/BeforeAfterAll

  2.times do
    it "starts a fresh leading edge debounce cycle before each example" do
      called = false

      debounce(for: 1.hour, leading: true, id: "rspec-debouncer-isolation") { called = true }

      expect(called).to be true
    end
  end

  context "when an example freezes time in the past" do
    before { Timecop.freeze(2000, 1, 1) }

    it "starts a fresh leading edge debounce cycle" do
      called = false

      debounce(for: 1.hour, leading: true, id: "rspec-debouncer-isolation") { called = true }

      expect(called).to be true
    end
  end

  context "with a persistent rule" do
    # rubocop:disable-next RSpec/LeakyLocalVariable -- observe the same persistent rule across examples
    executions = []
    let(:persistent_rule) { rules["rspec-rule-debouncer-isolation"] }

    # rubocop:disable RSpec/BeforeAfterAll
    before(:all) do
      built_rule = rule id: "rspec-rule-debouncer-isolation" do
        every :day
        debounce for: 1.hour, leading: true, idle_time: 2.hours
        run { executions << true }
      end
      built_rule.trigger
    end

    after(:all) do
      rules.remove("rspec-rule-debouncer-isolation")
    end
    # rubocop:enable RSpec/BeforeAfterAll

    before do
      executions.clear
      Timecop.freeze(2000, 1, 1)
    end

    2.times do
      it "resets debounce state while preserving the rule's settings" do
        persistent_rule.trigger
        persistent_rule.trigger

        expect(executions).to eq [true]
      end
    end
  end
end
