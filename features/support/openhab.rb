# frozen_string_literal: true

require_relative "openhab_rest"
require "English"
require "singleton"
require "tty-command"
require "fileutils"

Item = Struct.new(:type, :name, keyword_init: true)

def openhab_dir
  File.realpath "tmp/openhab"
end

def openhab_client(command)
  cmd = TTY::Command.new(printer: :null)
  cmd.run!(File.join(openhab_dir, "runtime/bin/client -p habopen  '#{command}'"), only_output_on_error: true)
end

def items_dir
  File.join(openhab_dir, "conf/items/")
end

def rules_dir
  File.join(openhab_dir, "conf/automation/jsr223/ruby/personal/")
end

def ruby_lib_dir
  File.join(openhab_dir, "conf/automation/lib/ruby/personal/")
end

def gem_home
  File.join(openhab_dir, "conf/scripts/lib/ruby/gem_home")
end

def services_dir
  File.join(openhab_dir, "conf/services")
end

def openhab_log
  File.join(openhab_dir, "userdata/logs/openhab.log")
end

def stop_openhab
  system("rake openhab:stop 1>/dev/null 2>/dev/null") || raise("Error Stopping openHAB")
end

def start_openhab
  system("rake openhab:start 1>/dev/null 2>/dev/null") || raise("Error Starting openHAB")
end

def ensure_openhab_running
  cmd = TTY::Command.new(printer: :null)
  cmd.run(File.join(openhab_dir, "runtime/bin/status"), only_output_on_error: true)
end

def check_log?(entry)
  check_log_regexp?(/#{Regexp.escape(entry)}/)
end

def check_log_regexp?(regexp)
  lines = File.foreach(openhab_log).select { |line| line.include?("Error during evaluation of script") }
  if lines.any?
    log(lines)
    raise "Error in script"
  end

  File.foreach(openhab_log).grep(regexp).any?
end

def add_item(item:)
  Rest.add_item(item:)
end

def install_feature(feature)
  return if feature_installed?(feature)

  openhab_client("feature:install #{feature}")
  wait_until(seconds: 120, msg: "Feature #{feature} not started") { feature_installed?(feature) }
end

def feature_installed?(feature)
  # System seems unsettled after adding a feature and sometimes openhab would restart
  # do not use optimized_client
  openhab_client("feature:list -i --no-format")
    .stdout.lines.grep(/#{feature}/).grep(/Started/).any?
end

def truncate_log
  File.open(openhab_log, File::TRUNC) {} # rubocop:disable Lint/EmptyBlock
end

def delete_things
  openhab_client("openhab:things clear")
end

def delete_rules
  FileUtils.rm Dir.glob(File.join(rules_dir, "*.rb"))
  deleted = false
  check_auth { Rest.rules }.each do |rule|
    uid = rule["uid"]
    Rest.delete_rule(uid)
    deleted = true
  end
  return unless deleted

  wait_until(seconds: 10, msg: "Rules not empty") { Rest.rules.empty? }
end

def delete_shared_libraries
  FileUtils.rm Dir.glob(File.join(ruby_lib_dir, "*.rb"))
end

def delete_items
  deleted = false
  Rest.items.each do |item|
    Rest.set_item_state(item["name"], "UNDEF")
    Rest.delete_item(item["name"])
    deleted = true
  end
  FileUtils.rm Dir.glob(File.join(items_dir, "*.items"))
  return unless deleted

  wait_until(seconds: 30, msg: "Items not empty") { Rest.items.empty? }
end

def enable_basic_auth
  openhab_client("config:property-set -p org.openhab.restauth allowBasicAuth true")
end

def retry_if_unauthorized(response)
  return response unless response.unauthorized?

  puts "Unauthorized. Enabling basic auth and retrying..."
  enable_basic_auth
  yield
end

def check_auth(&)
  yield.then { |response| retry_if_unauthorized(response, &) }
       .tap { |response| raise "Error in response: #{response.inspect}" unless response.success? }
end
