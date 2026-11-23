# frozen_string_literal: true

require "tmpdir"
require "fileutils"

require_relative "../../../../lib/openhab/thermos/addon_settings"

RSpec.describe OpenHAB::Thermos::AddonSettings do
  subject(:settings) { described_class.new }

  before { stub_const("JRUBY_VERSION", "10.1.1.0") }

  it "expands the same version placeholders as the addon" do
    allow(settings).to receive(:properties).and_return(
      "gem_home" => "/custom/{RUBY_ENGINE}/{RUBY_ENGINE_VERSION}/{RUBY_VERSION}"
    )
    expect(settings.gem_home).to eq "/custom/#{RUBY_ENGINE}/10.1.1.0/#{RUBY_VERSION}"
  end

  it "uses a configured directory without appending a version" do
    allow(settings).to receive(:properties).and_return("gem_home" => "/custom/shared gems")
    expect(settings.gem_home).to eq "/custom/shared gems"
  end

  it "preserves an explicitly empty gem_home" do
    allow(settings).to receive(:properties).and_return("gem_home" => "")
    expect(settings.gem_home).to eq ""
  end

  it "reads Felix settings without exposing its OSGi interfaces to JRuby", :jruby do
    skip "requires JRuby" unless RUBY_ENGINE == "jruby"
    require "jruby"
    runtimes = [ENV["OPENHAB_RUNTIME"],
                "/usr/share/openhab/runtime",
                File.expand_path("../../../../tmp/openhab/runtime", __dir__)]
    runtime = runtimes.compact.find do |path|
      !Dir.glob(File.join(path, "system/org/apache/felix/org.apache.felix.configadmin/*/*.jar")).empty?
    end
    skip "requires an openHAB runtime fixture" unless runtime

    original = ENV.to_h
    resources = lambda {
      JRuby.runtime.jruby_class_loader.get_resources("org/osgi/service/cm/ConfigurationListener.class").to_a.map(&:to_s)
    }
    before = resources.call
    Dir.mktmpdir do |directory|
      ENV["OPENHAB_USERDATA"] = directory
      ENV["OPENHAB_RUNTIME"] = runtime
      path = File.join(directory, "config/org/openhab/automation/jrubyscripting.config")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, 'gem_home="/custom\\=gems/{RUBY_ENGINE_VERSION}"')
      expect(settings.gem_home).to eq "/custom=gems/10.1.1.0"
      expect(resources.call).to eq before
    end
  ensure
    ENV.replace(original) if original
  end
end
