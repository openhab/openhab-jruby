# frozen_string_literal: true

require "cucumber/rake/task"
require "rspec/core/rake_task"

desc "Run standalone specs without starting openHAB"
RSpec::Core::RakeTask.new("spec:standalone") do |task|
  task.pattern = "spec/standalone/**/*_spec.rb"
  task.rspec_opts = ["--options", "/dev/null"]
end

desc "Run Cucumber Features"
task :features, [:feature] => ["openhab:warmup", "openhab:deploy"] do |_, args|
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = ["--format", "pretty", args[:feature]].compact
  end
end
