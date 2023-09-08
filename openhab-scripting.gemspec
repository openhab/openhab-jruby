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
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/openhab/openhab-jruby",
    "documentation_uri" => "https://openhab.github.io/openhab-jruby/",
    "changelog_uri" => "https://openhab.github.io/openhab-jruby/file.CHANGELOG.html",
    "rubygems_mfa_required" => "true"
  }

  spec.add_runtime_dependency "bundler", "~> 2.2"
  spec.add_runtime_dependency "marcel", "~> 1.0"
  spec.add_runtime_dependency "method_source", "~> 1.0"
  spec.add_runtime_dependency "ruby2_keywords", "~> 0.0"

  spec.add_development_dependency "cucumber", "~> 8.0"
  spec.add_development_dependency "cuke_linter", "~> 1.2"
  spec.add_development_dependency "faraday-retry", "~> 2.1"
  spec.add_development_dependency "gem-release", "~> 2.2"
  spec.add_development_dependency "github_changelog_generator", "~> 1.16"
  spec.add_development_dependency "guard-rubocop", "~> 1.5"
  spec.add_development_dependency "guard-shell", "~> 0.7"
  spec.add_development_dependency "guard-yard", "~> 2.2"
  spec.add_development_dependency "httparty", "~> 0.20"
  spec.add_development_dependency "irb", "~> 1.4"
  spec.add_development_dependency "nokogiri", "~> 1.13"
  spec.add_development_dependency "persistent_httparty", "~> 0.1"
  spec.add_development_dependency "process_exists", "~> 0.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.11"
  spec.add_development_dependency "rubocop", "~> 1.8"
  spec.add_development_dependency "rubocop-performance", "~> 1.11"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.11"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "tty-command", "~> 0.10"
  spec.add_development_dependency "yaml-lint", "~> 0.0"

  spec.files = Dir["{lib}/**/*"]
  spec.require_paths = ["lib"]
end
