# frozen_string_literal: true

unless RUBY_ENGINE == "jruby" &&
       Gem::Version.new(RUBY_ENGINE_VERSION) >= Gem::Version.new("9.3.8.0")
  raise Gem::RubyVersionMismatch, "openhab-jrubyscripting requires JRuby 9.3.8.0 or newer"
end

require "jruby"

require "diff/lcs"

require "openhab/log"

require_relative "rspec/configuration"
require_relative "rspec/helpers"
require_relative "rspec/karaf"
require_relative "rspec/hooks"

return unless defined?(RSpec)

RSpec.configure do |c|
  c.add_setting :openhab_automation_search_paths, default: [
    "#{org.openhab.core.OpenHAB.config_folder}/automation/ruby",
    "#{org.openhab.core.OpenHAB.config_folder}/automation/jsr223"
  ]
end
