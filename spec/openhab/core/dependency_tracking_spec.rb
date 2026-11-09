# frozen_string_literal: true

require "json"
require "open3"

RSpec.describe "Dependency tracking" do
  it "reports existing and newly required features exactly once" do
    # Use a separate runtime because dependency tracking modifies the load service
    # and Gem.loaded_specs for the lifetime of the script.
    script = <<~RUBY
      require "json"
      require "tmpdir"

      seen = []
      $dependencyListener = Object.new
      $dependencyListener.define_singleton_method(:accept) { |name| seen << name.to_s }

      Dir.mktmpdir do |dir|
        existing = File.join(dir, "existing.rb")
        added = File.join(dir, "added.rb")
        File.write(existing, "")
        File.write(added, "")
        require existing

        require "openhab/core/dependency_tracking"
        first_require = require added
        second_require = require added
        puts JSON.generate(existing: seen.count(existing), added: seen.count(added),
                           first_require: first_require, second_require: second_require)
      end
    RUBY

    lib = File.expand_path("../../../lib", __dir__)
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-I", lib, "-e", script)

    expect(status.success?).to be(true), stderr
    expect(JSON.parse(stdout)).to eq("existing" => 1,
                                     "added" => 1,
                                     "first_require" => true,
                                     "second_require" => false)
  end
end
