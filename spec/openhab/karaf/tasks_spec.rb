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
      command = (operation == "rebuild") ? "prepare(rebuild: true)" : "refresh"
      expect(tasks).to receive(:ruby).with(
        "-I",
        File.expand_path("../../../lib", __dir__),
        "-r",
        "openhab/rspec/karaf",
        "-e",
        "OpenHAB::RSpec::Karaf.new(File.join(Dir.pwd, '.karaf')).#{command}"
      )

      application["karaf:#{operation}"].invoke
    end
  end
end
