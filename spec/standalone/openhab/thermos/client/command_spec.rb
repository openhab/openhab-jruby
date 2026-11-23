# frozen_string_literal: true

require_relative "../../../../../lib/openhab/thermos/client"

RSpec.describe OpenHAB::Thermos::Client::Command do
  it "provides a shared interface for each client command" do
    commands = OpenHAB::Thermos::Client::COMMANDS
    expect(commands.keys).to include("binstub", "server", "status", "stop", "version")
    expect(commands.values.uniq).to all(be < described_class)
  end

  it "dispatches application commands to Run" do
    expect(OpenHAB::Thermos::Client.command_for("rspec")).to eq OpenHAB::Thermos::Client::Run
  end

  it "supports the version flag aliases without booting openHAB" do
    expect { OpenHAB::Thermos::Client.run(["--version"]) }
      .to output("thermos version #{OpenHAB::DSL::VERSION}\n").to_stdout
  end

  it "starts the explicit server in the foreground unless background is requested" do
    expect(OpenHAB::Thermos::Client::Server.new(["server"])).to be_foreground
    expect(OpenHAB::Thermos::Client::Server.new(["server", "--background"])).not_to be_foreground
  end
end
