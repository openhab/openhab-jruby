# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require "timeout"
require_relative "../../../../lib/openhab/thermos/server"

RSpec.describe OpenHAB::Thermos::RuntimeManager do
  it "configures Bundler before activating JSON or acknowledging startup" do
    gemfile = <<~RUBY
      raise "JSON was activated before Bundler" if Gem.loaded_specs.key?("json")
      File.write("bundler-configured", "yes")
    RUBY
    with_manager(gemfile) do |manager, directory|
      manager.send(:start_child)
      expect(File.read(File.join(directory, "bundler-configured"))).to eq "yes"
      expect(manager).to be_alive
    end
  end

  it "reports Bundler bootstrap errors through the client's stderr and exits unsuccessfully" do
    with_manager('raise "BOOTSTRAP_FAILURE"') do |manager|
      client, connection = UNIXSocket.pair
      input = Tempfile.new("input")
      output = Tempfile.new("output")
      error = Tempfile.new("error")
      [output, error, input].each { |stream| client.send_io(stream.to_io) }
      worker = Thread.new { manager.run(connection) }

      expect(Timeout.timeout(20) { client.gets }).to eq "1\n"
      expect(worker.join(20)).not_to be_nil
      worker.value
      expect(manager).not_to be_alive
      error.rewind
      expect(error.read).to include("BOOTSTRAP_FAILURE")
    ensure
      worker&.kill
      client&.close
      connection&.close unless connection&.closed?
      [input, output, error].compact.each(&:close!)
    end
  end

  def with_manager(gemfile)
    original = ENV.to_h
    Dir.mktmpdir("thermos-boot") do |directory|
      ENV["BUNDLE_GEMFILE"] = File.join(directory, "Gemfile")
      ENV["BUNDLE_LOCKFILE"] = nil
      ENV["BUNDLE_FROZEN"] = "false"
      ENV["BUNDLE_DEPLOYMENT"] = "false"
      ENV["RUBYOPT"] = nil
      ENV["BUNDLER_SETUP"] = nil
      ENV["THERMOS_TMP_PATH"] = directory
      File.write(ENV.fetch("BUNDLE_GEMFILE"), gemfile)
      launcher = instance_double(OpenHAB::Thermos::Launcher, command: [RbConfig.ruby])
      allow(OpenHAB::Thermos::Launcher).to receive(:new).and_return(launcher)
      log = Tempfile.new("thermos bootstrap")
      environment = OpenHAB::Thermos::Env.new(root: directory, log_file: log)
      manager = described_class.new({}, environment)
      yield manager, directory
    ensure
      manager&.stop
      log&.close!
    end
  ensure
    ENV.replace(original)
  end
end
