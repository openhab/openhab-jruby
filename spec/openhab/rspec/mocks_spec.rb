# frozen_string_literal: true

RSpec.describe "mocks" do
  it "runs callbacks on the main thread before OpenHAB::Core is initialized" do
    executor = OpenHAB::RSpec::Mocks::SynchronousExecutor.instance
    main_thread = executor.main_thread
    executor.main_thread = Thread.current
    hide_const("OpenHAB::Core")

    submitted = false
    runnable = java.lang.Runnable.impl { submitted = true }
    expect(executor.submit(runnable).get(5, java.util.concurrent.TimeUnit::SECONDS)).to be_nil
    expect(submitted).to be true

    executed = false
    runnable = java.lang.Runnable.impl { executed = true }
    executor.execute(runnable)
    expect(executed).to be true
  ensure
    executor.main_thread = main_thread
  end

  it "mocks against the actual item" do
    items.build { switch_item Switch1 }

    expect(Switch1).to receive(:command).with(ON).twice

    Switch1.on
    Switch1 << ON
  end

  context "without consistent proxies" do
    self.consistent_proxies = false

    it "only mocks the proxy" do
      items.build { switch_item Switch1 }

      expect(Switch1.__getobj__).to receive(:command).with(ON).twice
      expect(Switch1).not_to receive(:command)

      Switch1.on
      Switch1 << ON
    end
  end
end
