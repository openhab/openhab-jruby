# frozen_string_literal: true

require "httparty"
require "persistent_httparty"

#
# Rest interface for openHAB
#
class Rest
  include HTTParty

  persistent_connection_adapter

  def self.openhab_port
    @openhab_port ||= ENV["OPENHAB_HTTP_PORT"] || 8080
  end

  format :json
  base_uri "http://127.0.0.1:#{openhab_port}"
  basic_auth "foo", "foo"

  def self.rules
    get("/rest/rules")
  end

  def self.items
    get("/rest/items")
  end

  def self.set_item_state(name, state)
    put "/rest/items/#{name}/state", headers: text, body: state
  end

  def self.delete_item(name)
    delete "/rest/items/#{name}"
  end

  def self.delete_rule(uid)
    delete "/rest/rules/#{uid}"
  end

  def self.json
    { "Content-Type" => "application/json" }
  end

  def self.text
    { "Content-Type" => "text/plain" }
  end

  def self.add_item(item:)
    body = item_body(item)
    put("/rest/items/#{item.name}", headers: json, body: body.to_json)
    set_item_state(item.name, "UNDEF")
  end

  def self.item_body(item)
    body = {}
    body[:type] = item.type
    body[:name] = item.name
    body
  end
end
