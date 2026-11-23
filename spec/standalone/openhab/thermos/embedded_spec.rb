# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "rubygems"

RSpec.describe "Thermos embedded gem setup" do
  around do |example|
    original = ENV.to_h
    Dir.mktmpdir do |directory|
      ENV["OPENHAB_CONF"] = directory
      ENV["OPENHAB_USERDATA"] = directory
      example.run
    end
  ensure
    ENV.replace(original)
    Gem.clear_paths
  end

  before { stub_const("JRUBY_VERSION", "10.1.1.0") }

  it "uses the installed addon gems for the running JRuby version" do
    gem_home = File.join(ENV.fetch("OPENHAB_CONF"), "automation/ruby/.gem/10.1.1.0")
    FileUtils.mkdir_p(gem_home)
    load File.expand_path("../../../../lib/openhab/thermos/embedded.rb", __dir__)
    expect(Gem.dir).to eq gem_home
    expect(Gem.path).to include(gem_home)
  end

  it "uses the addon default when gem_home is not configured" do
    gem_home = File.join(ENV.fetch("OPENHAB_CONF"), "automation/ruby/.gem/10.1.1.0")
    load File.expand_path("../../../../lib/openhab/thermos/embedded.rb", __dir__)
    expect(Gem.dir).to eq gem_home
  end
end
