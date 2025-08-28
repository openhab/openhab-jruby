# frozen_string_literal: false

require "tempfile"
require "fileutils"
require "securerandom"

def require_openhab
  "require 'openhab/dsl'"
end

def doc_string_to_rule(doc_string)
  "#{require_openhab}\n\n#{doc_string}\n"
end

def identifying_log_line(uid)
  "Processing Complete for #{uid}"
end

def append_identifying_log_line_to_rule(code, uid)
  code << %[\n\nlogger.info("#{identifying_log_line(uid)}")\n\n]
end

def atomic_rule_write(rule_content, deploy_path)
  temp_file = Tempfile.create(["cucumber_test", ".rb"], File.join(openhab_dir, "userdata/tmp"))
  temp_file.write(rule_content)
  temp_file.close

  FileUtils.move temp_file, deploy_path
end

def deploy_shared_file(**kwargs)
  # check is always false, because shared code is never run immmediately
  deploy_ruby_file(directory: ruby_lib_dir, check: false, **kwargs)
end

def deploy_rule
  deploy_ruby_file(directory: rules_dir, code: @rule)
  sleep 1
end

def wait_for_rule(log_line)
  if ENV["RELOAD_SCRIPTS_BUNDLE"]
    # force the bundle for ScriptFileWatcher to re-scan immediately; otherwise
    # it can take up to 20s to notice the new rule file when Java's
    # WatchService doesn't support actively watching, and only polls (i.e. on
    # MacOS)
    openhab_client("bundle:restart org.openhab.core.automation.module.script.rulesupport")
  end
  wait_until(seconds: 60, msg: "Rule not added") { check_log?(log_line) }
end

def deploy_ruby_file(code:, directory:, filename: "", check: true)
  uid = SecureRandom.uuid

  log_line = identifying_log_line(uid)

  append_identifying_log_line_to_rule(code, uid) if check
  atomic_rule_write(code, File.join(directory, filename))
  wait_for_rule(log_line) if check
end

Given("a rule(:)") do |doc_string|
  @rule = doc_string_to_rule(doc_string)
end

Given("a deployed rule(:)") do |doc_string|
  @rule = doc_string_to_rule(doc_string)
  deploy_rule
end

When("I deploy the rule(:)") do
  deploy_rule
end

Given("code in a shared file named {string}(:)") do |file, doc_string|
  code = doc_string_to_rule(doc_string)
  deploy_shared_file(filename: file, code:)
end

When("I deploy the rules file") do
  deploy_rule
end

When("I remove the rules file") do
  delete_rules
end
