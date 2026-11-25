# frozen_string_literal: true

require "tmpdir"
require_relative "../../../../lib/openhab/thermos/client"

RSpec.describe OpenHAB::Thermos::Launcher do
  let(:directory) { ENV.fetch("OPENHAB_HOME") }

  around do |example|
    original = ENV.to_h
    Dir.mktmpdir do |directory|
      ENV["OPENHAB_HOME"] = directory
      ENV["OPENHAB_RUNTIME"] = File.join(directory, "runtime")
      ENV["OPENHAB_USERDATA"] = File.join(directory, "userdata")
      ENV["JAVA_HOME"] = File.join(directory, "java home")
      example.run
    end
  ensure
    ENV.replace(original)
  end

  it "removes CRuby gem paths and startup hooks from the server environment" do
    stub_const("RUBY_ENGINE", "ruby")
    environment = described_class.new(directory).environment
    expect(environment).to include("GEM_HOME" => nil,
                                   "GEM_PATH" => nil,
                                   "RUBYOPT" => nil,
                                   "RUBYLIB" => nil,
                                   "BUNDLER_SETUP" => nil)
    expect(environment).not_to have_key("OPENHAB_RUNTIME")
  end

  it "preserves the environment when already running under JRuby" do
    stub_const("RUBY_ENGINE", "jruby")
    expect(described_class.new(directory).environment).to be_empty
  end

  it "finds an addon in the userdata Maven cache and preserves arguments containing spaces" do
    stub_const("RUBY_ENGINE", "ruby")
    jar = File.join(directory, "userdata/tmp/mvn/addons/org.openhab.automation.jrubyscripting-5.3.jar")
    FileUtils.mkdir_p(File.dirname(jar))
    File.write(jar, "addon")

    expect(described_class.new(directory).command(jvm_options: ["--add-opens=java.base/java.io=ALL-UNNAMED"]))
      .to eq [File.join(ENV.fetch("JAVA_HOME"), "bin/java"),
              *described_class::JVM_OPTIONS,
              "-Dthermos.jruby.jar=#{jar}",
              "-cp",
              jar,
              "org.jruby.Main",
              "-r",
              File.expand_path("../../../../lib/openhab/thermos/embedded.rb", __dir__)]
  end

  it "finds manually installed addons and uses Java from PATH without JAVA_HOME" do
    stub_const("RUBY_ENGINE", "ruby")
    ENV.delete("JAVA_HOME")
    jar = File.join(directory, "addons/org.openhab.automation.jrubyscripting-5.3.jar")
    FileUtils.mkdir_p(File.dirname(jar))
    File.write(jar, "addon")
    expect(described_class.new(directory).command.first).to eq "java"
    expect(described_class.new(directory).command).to include(jar)
  end

  it "finds addons extracted from a KAR archive" do
    stub_const("RUBY_ENGINE", "ruby")
    jar = File.join(directory,
                    "userdata/tmp/kar/openhab-addons-5.3/org/openhab/addons/bundles",
                    "org.openhab.automation.jrubyscripting/5.3/org.openhab.automation.jrubyscripting-5.3.jar")
    FileUtils.mkdir_p(File.dirname(jar))
    File.write(jar, "addon")

    expect(described_class.new(directory).command).to include("-cp", jar, "org.jruby.Main")
  end

  it "selects the most recently updated addon from the runtime repository" do
    stub_const("RUBY_ENGINE", "ruby")
    jars = %w[5.2 5.3].map do |version|
      path = File.join(directory, "runtime/system/org/openhab/org.openhab.automation.jrubyscripting-#{version}.jar")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "addon")
      path
    end
    File.utime(Time.at(0), Time.at(0), jars.first)
    expect(described_class.new(directory).command).to include(jars.last)
  end

  it "reuses the embedded distribution for a child launched under JRuby", :jruby do
    skip "requires JRuby" unless RUBY_ENGINE == "jruby"
    properties = java.lang.System.get_properties
    previous = properties.set_property("thermos.jruby.jar", "/embedded/addon.jar")
    expect(described_class.new(directory).command).to include("-cp", "/embedded/addon.jar", "org.jruby.Main")
  ensure
    if properties
      previous ? properties.set_property("thermos.jruby.jar", previous) : properties.remove("thermos.jruby.jar")
    end
  end
end
