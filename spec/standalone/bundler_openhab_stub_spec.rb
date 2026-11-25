# frozen_string_literal: true

require "bundler"
require "bundler/plugin"
require "tmpdir"

RSpec.describe "bundler-openhab-stub inside a ScriptEngine" do
  def evaluate_plugin(gemfile)
    context = Object.new
    %i[org openhab core OpenHAB].each { |name| context.define_singleton_method(name) { self } }
    context.define_singleton_method(:version) { "5.3.0" }
    allow(Bundler::Plugin).to receive(:add_hook) { |_event, &hook| hook.call(gemfile, nil) }
    allow(Gem).to receive(:post_reset)
    plugin = File.expand_path("../../plugins.rb", __dir__)
    context.instance_eval(File.read(plugin), plugin)
  end

  it "supplies the repository lockfile's version even when openHAB is available" do
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "openhab-scripting.gemspec"), "")
      expect(Gem::Specification).to receive(:add_spec) do |spec|
        expect(spec.name).to eq "openhab"
        expect(spec.version).to eq Gem::Version.new("5.0.3")
        expect(spec.installation_missing?).to be false
      end
      evaluate_plugin(File.join(directory, "Gemfile"))
    end
  end

  it "leaves an ordinary user's addon-provided gem alone" do
    Dir.mktmpdir do |directory|
      expect(Gem::Specification).not_to receive(:add_spec)
      evaluate_plugin(File.join(directory, "Gemfile"))
    end
  end
end
