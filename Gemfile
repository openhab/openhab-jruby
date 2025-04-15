# frozen_string_literal: true

source "https://rubygems.org"

# see https://github.com/jruby/jruby/issues/8606
# once we no longer support a JRuby < 9.4.12.0 (openHAB 5.0+), this can be removed
# @deprecated OH 5.0
gem "jar-dependencies", "0.4.1", platform: :jruby, require: false

gemspec

group :development do
  gem "debug", "~> 1.9", platform: :mri
  gem "gem-release", "~> 2.2"
  gem "puma", "~> 6.6", platform: :mri
  gem "rackup", "~> 2.2", platform: :mri
end

group :development, :test do
  gem "coderay", "~> 1.1.3", platform: :mri
  gem "commonmarker", "~> 2.0", platform: :mri
  gem "nokogiri", "~> 1.15", require: false
  gem "process_exists", "~> 0.2", require: false
  gem "rake", "~> 13.0", require: false
  gem "rubocop-inst", "~> 1.0", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rubocop-rspec", "~> 3.5", require: false
  gem "tty-command", "~> 0.10", require: false
  gem "yaml-lint", "~> 0.0", require: false
  gem "yard", platform: :mri, github: "ccutrer/yard", branch: "integration", require: false
end

group :test do
  gem "cucumber", "~> 9.2", require: false
  gem "cuke_linter", "~> 1.2", require: false
  gem "httparty", "~> 0.20", require: false
  gem "irb", "~> 1.15", require: false
  gem "persistent_httparty", "~> 0.1", require: false
  gem "rspec", "~> 3.11", require: false
  gem "timecop", "~> 0.9", require: false
end
