# frozen_string_literal: true

require "openhab/rspec/jruby"

RSpec.describe OpenHAB::RSpec::JRuby::OSGiBundleClassLoader do # rubocop:disable RSpec/SpecFilePathFormat
  let(:bundle) { object_double(OpenHAB::OSGi.bundle_context.bundle) }

  it "delegates application classes to the bundle" do
    loader = described_class.new(bundle, isolated: true)
    expect(bundle).to receive(:load_class).with("org.openhab.core.OpenHAB").and_return(:loaded)
    expect(loader.load_class("org.openhab.core.OpenHAB")).to eq :loaded
  end

  it "keeps another runtime's JRuby classes out of an isolated engine" do
    loader = described_class.new(bundle, isolated: true)
    expect(bundle).not_to receive(:load_class)
    %w[org.jruby.Ruby org.jcodings.Encoding org.joni.Regex].each do |name|
      expect { loader.load_class(name) }.to raise_error(Java::JavaLang::ClassNotFoundException)
    end
  end

  it "preserves bundle access for the launcher runtime" do
    expect(bundle).to receive(:load_class).with("org.jruby.Ruby").and_return(:loaded)
    expect(described_class.new(bundle).load_class("org.jruby.Ruby")).to eq :loaded
  end
end
