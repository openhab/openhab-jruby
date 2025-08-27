# frozen_string_literal: true

require "securerandom"
require "json"

Given("Clean OpenHAB with latest Ruby Libraries") do
  attempt = 1
  begin
    delete_rules
    delete_shared_libraries
    delete_items
    delete_things
    truncate_log
  rescue => e
    raise if attempt > 2

    attempt += 1
    puts "Error encountered: #{e.message}. Restarting Openhab for attempt ##{attempt}"
    stop_openhab
    start_openhab
    retry
  end
end

Then(/^It should log '([^']*)' within (\d+) seconds$/) do |string, seconds|
  wait_until(seconds: seconds.to_i,
             msg: "'#{string}' not found in log file (#{openhab_log}) within #{seconds} seconds") do
    check_log?(string)
  end
end

Then("It should not log {string} within {int} seconds") do |string, seconds|
  not_for(seconds:, msg: "'#{string}'' found in log file (#{openhab_log}) within #{seconds} seconds") do
    check_log?(string)
  end
end

def nil_if_blank(str)
  str = nil if str&.strip == ""
  str
end

def check_items(added:)
  wait_until(seconds: 10, msg: "Not all #{added} items were added") do
    (added.map(&:name) - Rest.items.map { |item| item["name"] }).empty?
  rescue
    false
  end
end

Given(/(?: I add)?items:/) do |table|
  items = []
  table.hashes.each do |row|
    item = Item.new(type: row["type"], name: row["name"])
    add_item(item:)
    items << item
  end
  check_items(added: items)
end

When("item {string} state is changed to {string}") do |item, state|
  openhab_client("openhab:send #{item} #{state}")
end

Given("feature {string} installed") do |feature|
  install_feature(feature)
end

def array_from_list(*list)
  list.compact.flat_map { |data| data.split(",").map(&:strip) }
end
