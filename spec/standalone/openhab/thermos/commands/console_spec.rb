# frozen_string_literal: true

require "tmpdir"
require "open3"
require "rbconfig"

require_relative "../../../../../lib/openhab/thermos/commands"

RSpec.describe OpenHAB::Thermos::Commands::Console do
  it "registers an IRB command with a console binstub" do
    command = OpenHAB::Thermos.command("console")
    expect(command.command).to be_a described_class
    expect(command.exec_name).to eq "irb"
    expect(command.gem_name).to eq "irb"
    expect(command.binstub_name).to eq "bin/console"
  end

  it "runs IRB using the provided streams without reopening descriptors or inheriting Ruby startup hooks" do
    previous_rubyopt = ENV["RUBYOPT"]
    previous_bundler_setup = ENV["BUNDLER_SETUP"]
    ENV["RUBYOPT"] = "-rthermos_unexpected_bootstrap"
    ENV["BUNDLER_SETUP"] = "/thermos_unexpected_bootstrap.rb"
    script = <<~RUBY
      require "openhab/thermos/commands"
      require "irb"
      module OpenHAB
        module RSpec
          module Configuration
            def self.private_confdir = false
          end
          module Helpers
            def self.autorequires; end
            def self.load_transforms; end
            def self.load_rules; end
          end
        end
        module DSL; end
      end
      bootstrap = Object.new
      def bootstrap.setup; end
      OpenHAB::Thermos.register_command("rspec", bootstrap)
      OpenHAB::Thermos.context = {}
      ARGV.replace(%w[-f --simple-prompt --noreadline])
      original_open = IO.method(:open)
      IO.define_singleton_method(:open) do |descriptor, *args, **kwargs, &block|
        if [STDIN.fileno, STDOUT.fileno, STDERR.fileno].include?(descriptor)
          raise "IRB reopened a borrowed descriptor"
        end
        original_open.call(descriptor, *args, **kwargs, &block)
      end
      OpenHAB::Thermos::Commands::Console.new.call
    RUBY
    lib = File.expand_path("../../../../../lib", __dir__)
    command = [RbConfig.ruby, "-I", lib, "-e", script]
    input = "puts :THERMOS_CONSOLE_INPUT_OK\nexit\n"
    output, error, status = Open3.capture3({ "RUBYOPT" => nil, "BUNDLER_SETUP" => nil }, *command, stdin_data: input)
    expect(status.success?).to be(true), error
    expect(output).to include("THERMOS_CONSOLE_INPUT_OK")
  ensure
    ENV["RUBYOPT"] = previous_rubyopt
    ENV["BUNDLER_SETUP"] = previous_bundler_setup
  end

  it "shares the RSpec command's cached runtime setup" do
    command = instance_double(OpenHAB::Thermos::CommandWrapper)
    allow(OpenHAB::Thermos).to receive(:command).with("rspec").and_return(command)
    expect(command).to receive(:setup)
    described_class.new.setup
  end
end
