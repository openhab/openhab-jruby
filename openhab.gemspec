# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "openhab"
  spec.version = "0.a"
  spec.licenses = ["EPL-2.0"]
  spec.authors = ["Cody Cutrer"]
  spec.email = ["cody@cutrer.us"]

  spec.summary = "Dummy gem for openHAB to satisfy gem dependencies"
  spec.description = <<~TEXT
    This is a dummy gem for openHAB to satisfy gem dependencies.
    It does not contain any functionality, and should not actually be installed.
  TEXT
  spec.homepage = "https://openhab.org/"

  spec.required_ruby_version = Gem::Requirement.new("<= 0.a") # rubocop:disable Gemspec/RequiredRubyVersion

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/openhab/openhab-jruby",
    "documentation_uri" => "https://openhab.github.io/openhab-jruby/",
    "rubygems_mfa_required" => "true"
  }
end
