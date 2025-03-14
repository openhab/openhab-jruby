# frozen_string_literal: true

require "bundler"

# rubocop:disable Style/GlobalVars

$skip_openhab_dependency = true
$openhab_scripting_gem_name = "rspec-openhab-scripting"
begin
  Bundler.load_gemspec_uncached("openhab-scripting.gemspec")
ensure
  $skip_openhab_dependency = false
  $openhab_scripting_gem_name = nil
end

# rubocop:enable Style/GlobalVars
