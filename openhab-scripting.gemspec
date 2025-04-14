# frozen_string_literal: true

require_relative "lib/openhab/dsl/version"

Gem::Specification.new do |spec|
  spec.name          = "openhab-scripting"
  spec.version       = OpenHAB::DSL::VERSION
  spec.licenses      = ["EPL-2.0"]
  spec.authors       = ["Brian O'Connell", "Cody Cutrer", "Jimmy Tanagra"]
  spec.email         = ["broconne+github@gmail.com", "cody@cutrer.us", "jcode@tanagra.id.au"]

  spec.summary       = "JRuby Helper Libraries for openHAB Scripting"
  spec.homepage      = "https://openhab.github.io/openhab-jruby/"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.4")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/openhab/openhab-jruby",
    "documentation_uri" => "https://openhab.github.io/openhab-jruby/",
    "changelog_uri" => "https://openhab.github.io/openhab-jruby/file.CHANGELOG.html",
    "rubygems_mfa_required" => "true"
  }

  spec.add_dependency "bundler", "~> 2.2"
  spec.add_dependency "irb", "~> 1.15"
  spec.add_dependency "marcel", "~> 1.0"
  spec.add_dependency "method_source", "~> 1.0"

  spec.add_development_dependency "cucumber", "~> 8.0"
  spec.add_development_dependency "cuke_linter", "~> 1.2"
  spec.add_development_dependency "gem-release", "~> 2.2"
  spec.add_development_dependency "httparty", "~> 0.20"
  spec.add_development_dependency "persistent_httparty", "~> 0.1"
  spec.add_development_dependency "process_exists", "~> 0.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.11"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "tty-command", "~> 0.10"
  spec.add_development_dependency "yaml-lint", "~> 0.0"

  spec.files = Dir["{lib}/**/*"]
  spec.require_paths = ["lib"]
end
