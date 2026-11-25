# frozen_string_literal: true

# Execute these functions on start

require "rbconfig"

require_relative "openhab"

def openhab_deploy
  system(RbConfig.ruby, File.expand_path("../../bin/rake", __dir__), "openhab:deploy") ||
    raise("Error Deploying Libraries")
end

def prepare_openhab
  openhab_deploy
  ensure_openhab_running
end

prepare_openhab
