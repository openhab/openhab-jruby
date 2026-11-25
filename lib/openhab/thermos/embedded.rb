# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

# Loaded before the coordinator requires any gems, using the addon's JRuby version.
require "rubygems"

require_relative "addon_settings"

gem_home = OpenHAB::Thermos::AddonSettings.new.gem_home
unless gem_home.empty?
  ENV["GEM_HOME"] = gem_home
  ENV["GEM_PATH"] = ([gem_home] + Gem.path).uniq.join(File::PATH_SEPARATOR)
  Gem.clear_paths
end
