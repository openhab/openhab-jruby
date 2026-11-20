# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "bundler-openhab-stub"
  spec.version       = "1.0.0"
  spec.licenses      = ["EPL-2.0"]
  spec.authors       = ["Cody Cutrer"]
  spec.email         = ["cody@cutrer.us"]

  spec.summary       =
    "Bundler plugin that stubs the openHAB gem to satisfy the dependency when the openHAB runtime is not present"
  spec.homepage      = "https://openhab.github.io/openhab-jruby/main/file.testing.html"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.4.2")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/openhab/openhab-jruby",
    "documentation_uri" => "https://openhab.github.io/openhab-jruby/main/file.testing.html",
    "changelog_uri" => "https://openhab.github.io/openhab-jruby/file.CHANGELOG.html",
    "rubygems_mfa_required" => "true"
  }

  spec.add_dependency "bundler", "~> 4.1"

  spec.files         = %w[plugins.rb]
  spec.require_paths = ["lib"]
end
