# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"

RSpec.describe "RSpec command setup" do
  it "loads requires and load paths from RSpec options without running specs" do
    Dir.mktmpdir do |directory|
      FileUtils.mkdir_p(File.join(directory, "support"))
      File.write(File.join(directory, ".rspec"), "-I support\n--require custom_helper\n")
      File.write(File.join(directory, ".rspec-local"), "--require local_helper\n")
      File.write(File.join(directory, "support/custom_helper.rb"), 'puts "CUSTOM HELPER"')
      File.write(File.join(directory, "support/local_helper.rb"), 'puts "LOCAL HELPER"')
      FileUtils.mkdir_p(File.join(directory, "spec"))
      File.write(File.join(directory, "spec/not_loaded_spec.rb"), 'raise "specs must not run during setup"')
      output, error, status = run_setup(directory)
      expect(status.success?).to be(true), error
      expect(output.lines.map(&:chomp)).to eq ["CUSTOM HELPER", "LOCAL HELPER", "SETUP COMPLETE"]
    end
  end

  it "fails setup when a configured require cannot be loaded" do
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, ".rspec"), "--require missing_thermos_helper\n")
      _output, error, status = run_setup(directory)
      expect(status.success?).to be false
      expect(error).to include("RSpec setup failed")
    end
  end

  def run_setup(directory)
    script = <<~RUBY
      require "openhab/thermos/commands"
      command = OpenHAB::Thermos.command("rspec")
      command.setup
      command.setup
      puts "SETUP COMPLETE"
    RUBY
    lib = File.expand_path("../../../../../lib", __dir__)
    command = [RbConfig.ruby, "-I", lib, "-e", script]
    Open3.capture3({ "SPEC_OPTS" => nil, "RUBYOPT" => nil, "BUNDLER_SETUP" => nil }, *command, chdir: directory)
  end
end
