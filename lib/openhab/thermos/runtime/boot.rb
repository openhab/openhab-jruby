# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require "bundler/setup"

require_relative "../runtime"

Process.setsid
runtime = OpenHAB::Thermos::Runtime.new(
  UNIXSocket.open(ENV.delete("THERMOS_MANAGER_SOCKET")),
  JSON.parse(ENV.delete("THERMOS_ORIGINAL_ENV")),
  OpenHAB::Thermos::Env.new(log_file: $stdout)
)
Signal.trap("TERM") { runtime.terminate }
OpenHAB::Thermos::ProcessTitleUpdater.run do |distance|
  "thermos runtime | #{runtime.app_name} | started #{distance} ago"
end
runtime.run
