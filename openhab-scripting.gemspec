# frozen_string_literal: true

require_relative "lib/openhab/dsl/version"
# allows CI stuff to work, but is stripped out when the gem is built
require_relative "lib/openhab/core/gem"

Gem::Specification.new do |spec|
  spec.name          = "openhab-scripting"
  spec.version       = OpenHAB::DSL::VERSION
  spec.licenses      = ["EPL-2.0"]
  spec.authors       = ["Brian O'Connell", "Cody Cutrer", "Jimmy Tanagra"]
  spec.email         = ["broconne+github@gmail.com", "cody@cutrer.us", "jcode@tanagra.id.au"]

  spec.summary       = "JRuby Helper Libraries for openHAB Scripting"
  spec.homepage      = "https://openhab.github.io/openhab-jruby/"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.4.2")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/openhab/openhab-jruby",
    "documentation_uri" => "https://openhab.github.io/openhab-jruby/",
    "changelog_uri" => "https://openhab.github.io/openhab-jruby/file.CHANGELOG.html",
    "rubygems_mfa_required" => "true"
  }

  spec.add_dependency "bigdecimal", "~> 4.0"
  spec.add_dependency "bundler", ">= 2.2", "< 5.0"
  spec.add_dependency "csv", "~> 3.0"
  spec.add_dependency "marcel", "~> 1.0"
  spec.add_dependency "method_source", "~> 1.0"
  # ENV var *only* for use from CI for Cucumber
  spec.add_dependency "openhab", ">= 5.0.0", "< 5.3" unless ENV["OPENHAB_NO_RUNTIME_DEP"]

  spec.files = Dir["{lib}/**/*"]
  spec.require_paths = ["lib"]
end
