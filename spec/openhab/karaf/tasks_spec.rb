# frozen_string_literal: true

require "openhab/karaf/tasks"

RSpec.describe OpenHAB::Karaf::Tasks do
  let(:application) { Rake::Application.new }
  let(:tasks) { described_class.new }

  around do |example|
    original = Rake.application
    Rake.application = application
    example.run
  ensure
    Rake.application = original
  end

  %w[rebuild refresh].each do |operation|
    it "runs karaf:#{operation} in a separate Ruby process" do
      allow(OpenHAB::RSpec::Configuration).to receive(:karaf_path).and_return(nil)
      command = (operation == "rebuild") ? "prepare(rebuild: true)" : "refresh"
      expect(tasks).to receive(:ruby).with(
        "-I",
        File.expand_path("../../../lib", __dir__),
        "-r",
        "openhab/rspec/karaf",
        "-e",
        "OpenHAB::RSpec::Karaf.new(nil).#{command}"
      )

      application["karaf:#{operation}"].invoke
    end
  end

  it "defaults to the configured Karaf path" do
    allow(OpenHAB::RSpec::Configuration).to receive(:karaf_path).and_return("/tmp/test-karaf")

    expect(tasks.karaf_path).to eq "/tmp/test-karaf"
  end

  it "falls back to the configured path when the block assigns nil" do
    allow(OpenHAB::RSpec::Configuration).to receive(:karaf_path).and_return("/tmp/test-karaf")
    tasks = described_class.new { |config| config.karaf_path = nil }

    expect(tasks.karaf_path).to eq "/tmp/test-karaf"
  end

  it "allows a block to override the path and safely passes it to the subprocess" do
    path = %q(/tmp/karaf with 'single' and "double" quotes and #{interpolation})
    tasks = described_class.new { |config| config.karaf_path = path }
    expect(tasks).to receive(:ruby).with(
      "-I",
      File.expand_path("../../../lib", __dir__),
      "-r",
      "openhab/rspec/karaf",
      "-e",
      "OpenHAB::RSpec::Karaf.new(#{path.dump}).refresh"
    )

    application["karaf:refresh"].invoke
  end
end
