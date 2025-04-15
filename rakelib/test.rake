# frozen_string_literal: true

require "cucumber/rake/task"

desc "Run Cucumber Features"
task :features, [:feature] => ["openhab:warmup", "openhab:deploy"] do |_, args|
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty #{args[:feature]}"
  end
end
