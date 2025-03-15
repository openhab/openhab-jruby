# frozen_string_literal: true

source "https://rubygems.org"

# see https://github.com/jruby/jruby/issues/8606
# once we no longer support a JRuby < 9.4.12.0 (openHAB 5.0+), this can be removed
# @deprecated OH 5.0
gem "jar-dependencies", "0.4.1", platform: :jruby, require: false

gemspec

gem "debug", "~> 1.9", require: false, platform: :mri
gem "nokogiri", "~> 1.15", require: false
gem "rubocop-inst", "~> 1.0", require: false
gem "rubocop-rake", "~> 0.6", require: false
gem "rubocop-rspec", "~> 3.5", require: false

gem "coderay", "~> 1.1.3", require: false, platform: :mri
gem "commonmarker", require: false, platform: :mri
gem "thin", "~> 1.8.1", require: false, platform: :mri
gem "yard", require: false, platform: :mri, github: "ccutrer/yard", branch: "integration"
