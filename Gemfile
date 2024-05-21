# frozen_string_literal: true

source "https://rubygems.org"

gemspec

plugin "bundler-multilock", "1.3.1"
return unless Plugin.installed?("bundler-multilock")

Plugin.send(:load_plugin, "bundler-multilock")

lockfile active: RUBY_VERSION >= "2.7" do
  # these gems are not compatible with Ruby 2.6/JRuby 9.3, but we don't need them to actually
  # run tests

  gem "debug", "~> 1.9", require: false, platform: :mri
  gem "irb", "~> 1.6"
  gem "nokogiri", "~> 1.15"
  gem "rubocop-inst", "~> 1.0"
  gem "rubocop-rake", "~> 0.6"
  gem "rubocop-rspec", "~> 2.11"
end

lockfile "ruby-2.6", active: RUBY_VERSION < "2.7" do
  # no additional gems
end

gem "coderay", "~> 1.1.3", require: false, platform: :mri
gem "commonmarker", require: false, platform: :mri
gem "thin", "~> 1.8.1", require: false, platform: :mri
gem "yard", require: false, platform: :mri, github: "ccutrer/yard", branch: "integration"
