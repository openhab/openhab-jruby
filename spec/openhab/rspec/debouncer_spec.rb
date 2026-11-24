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
end
