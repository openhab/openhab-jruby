# frozen_string_literal: true

require "tmpdir"
require_relative "../../../../../lib/openhab/thermos/client"
require_relative "../../../../../lib/openhab/thermos/commands"

RSpec.describe OpenHAB::Thermos::Client::Binstub do
  around do |example|
    original_env = ENV.to_h
    original_commands = OpenHAB::Thermos.commands.dup
    Dir.mktmpdir do |directory|
      ENV["BUNDLE_GEMFILE"] = File.join(directory, "Gemfile")
      File.write(ENV.fetch("BUNDLE_GEMFILE"), "source 'https://rubygems.org'\n")
      Dir.chdir(directory) { example.run }
    end
  ensure
    ENV.replace(original_env)
    OpenHAB::Thermos.commands.replace(original_commands)
  end

  it "installs an idempotent launcher and preserves existing binstub code" do
    FileUtils.mkdir_p("bin")
    original = "#!/usr/bin/env ruby\n# frozen_string_literal: true\nputs ARGV.inspect\n"
    File.write("bin/rspec", original)
    expect { described_class.call(%w[binstub rspec]) }.to output("* bin/rspec: thermos inserted\n").to_stdout
    enabled = File.read("bin/rspec")
    expect(enabled.sub(described_class::LOADER, "")).to eq original
    expect(File.read("bin/thermos")).to eq described_class::LAUNCHER
    expect(File.executable?("bin/thermos")).to be true
    expect(described_class::LAUNCHER).not_to include('require "bundler/setup"', '"spring"')
    expect { described_class.call(%w[binstub rspec]) }.to output("* bin/rspec: thermos already present\n").to_stdout
    expect(File.read("bin/rspec")).to eq enabled
  end

  it "generates a missing registered executable" do
    expect { described_class.call(%w[binstub rspec]) }.to output("* bin/rspec: generated with thermos\n").to_stdout
    expect(File.read("bin/rspec")).to include('load Gem.bin_path("rspec-core", "rspec")')
  end

  it "installs all registered commands and can remove their loaders" do
    OpenHAB::Thermos.register_command("custom")
    FileUtils.mkdir_p("bin")
    File.write("bin/custom", "#!/usr/bin/env ruby\nputs :custom\n")
    expect { described_class.call(["binstub", "--all"]) }.to output(<<~TEXT).to_stdout
      * bin/rspec: generated with thermos
      * bin/console: generated with thermos
      * bin/custom: thermos inserted
    TEXT
    expect(File.read("bin/rspec")).to include(described_class::LOADER)
    expect(File.read("bin/custom")).to include(described_class::LOADER)
    expect { described_class.call(["binstub", "--remove", "--all"]) }.to output(<<~TEXT).to_stdout
      * bin/rspec: thermos removed
      * bin/console: thermos removed
      * bin/custom: thermos removed
    TEXT
    expect(File.exist?("bin/thermos")).to be false
    expect(File.read("bin/custom")).to eq "#!/usr/bin/env ruby\nputs :custom\n"
  end

  it "refuses to overwrite an unrelated project launcher" do
    FileUtils.mkdir_p("bin")
    File.write("bin/thermos", "custom launcher")
    expect { described_class.call(["binstub"]) }.to raise_error(OpenHAB::Thermos::ClientError, /already exists/)
  end

  it "rejects unknown commands before writing files" do
    expect do
      expect { described_class.call(["binstub", "../rspec"]) }
        .to raise_error(SystemExit) { |error| expect(error.status).to eq 1 }
    end.to output("The '../rspec' command is not known to thermos.\n").to_stderr
    expect(File.exist?("bin/thermos")).to be false
  end
end
