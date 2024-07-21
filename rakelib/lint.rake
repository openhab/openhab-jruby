# frozen_string_literal: true

require "rubocop/rake_task"
require "cuke_linter"

namespace :lint do
  RuboCop::RakeTask.new do |task|
    task.patterns = ["lib/**/*.rb", "test/**/*.rb"]
    task.fail_on_error = false
  end

  desc "Cucumber Linting"
  task :cucumber do
    CukeLinter.lint
  end

  desc "YARD Docs"
  task :yard do
    sh("yard -c --no-cache --private --fail-on-warning --no-stats") &&
      sh("yard stats -c --list-undoc")
  end

  desc "Execute all lint tests"
  task all: %i[rubocop cucumber yard]
end
