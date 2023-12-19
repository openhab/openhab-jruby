# frozen_string_literal: true

source "https://rubygems.org"

gemspec

plugin "bundler-multilock", "~> 1.2"
return unless Plugin.installed?("bundler-multilock")

Plugin.send(:load_plugin, "bundler-multilock")

gem "coderay", "~> 1.1.3", require: false, platform: :mri
gem "commonmarker", require: false, platform: :mri
gem "debug", "~> 1.8.0", require: false, platform: :mri
gem "thin", "~> 1.8.1", require: false, platform: :mri
gem "yard", require: false, platform: :mri, github: "ccutrer/yard", branch: "integration"
