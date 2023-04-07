# frozen_string_literal: true

require "github_changelog_generator/task"

module GitHubChangelogGenerator
  class Generator
    # Don't add any header or footer
    def insert_fixed_string(log)
      log
    end
  end
end

directory "tmp"

desc "Generate Changelog"
task :changelog, %i[old_version new_version output] => ["tmp"] do |_task, args|
  old_version, new_version, new_filename = args.values_at(:old_version, :new_version, :output)
  unless old_version && new_version && new_filename
    raise ArgumentError, "old_version, new_version, and output arguments must be specified"
  end

  GitHubChangelogGenerator::RakeTask.new :new_changelog do |config|
    config.user = "openhab"
    config.project = "openhab-jruby"
    config.since_tag = "v#{old_version}"
    config.future_release = "v#{new_version}"
    config.bug_prefix = "### Bug Fixes"
    config.enhancement_prefix = "### Features"
    config.issues = true
    config.add_pr_wo_labels = false
    config.add_issues_wo_labels = false
    config.exclude_labels = ["documentation"]
    config.output = new_filename
  end

  Rake::Task["new_changelog"].execute

  insert_new_changelog(new_filename, main_filename: "CHANGELOG.md")
end

# Inserts the content of new_filename into the third line of the main_filename
# We want to preserve the first two lines which contain the changelog header
# Read/write line by line in case the changelog gets huge
def insert_new_changelog(new_filename, main_filename:)
  [main_filename, new_filename].each do |file|
    raise ArgumentError, "File '#{file}' doesn't exist" unless File.exist?(file)
  end

  temp_filename = "#{main_filename}.new"
  File.open(temp_filename, "w") do |temp_file|
    File.open(main_filename) do |main_file|
      2.times { temp_file.write main_file.gets } # Changelog header + blank line
      temp_file.write File.read(new_filename)
      main_file.each { |line| temp_file.write line }
    end
  end

  File.unlink(main_filename)
  File.rename(temp_filename, main_filename)
end
