# frozen_string_literal: true

require_relative "../../../../lib/openhab/thermos/command_wrapper"

RSpec.describe OpenHAB::Thermos::CommandWrapper do
  it "sets up a command only once" do
    command = Object.new
    def command.setup; end
    wrapper = described_class.new("custom", command)
    expect(command).to receive(:setup).once

    expect(wrapper.setup?).to be false
    expect(wrapper.setup).to be true
    expect(wrapper.setup).to be false
    expect(wrapper.setup?).to be true
  end

  it "allows commands without a setup hook" do
    wrapper = described_class.new("custom")
    expect(wrapper.setup).to be false
    expect(wrapper.setup?).to be true
  end

  it "retries setup if the hook fails" do
    command = Object.new
    def command.setup; end
    wrapper = described_class.new("custom", command)
    allow(command).to receive(:setup).and_raise("setup failed")
    expect { wrapper.setup }.to raise_error("setup failed")
    expect(wrapper.setup?).to be false

    allow(command).to receive(:setup)
    expect(wrapper.setup).to be true
  end
end
