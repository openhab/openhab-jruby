# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "../thermos"

command = File.basename($PROGRAM_NAME)
executable = File.expand_path("../../../exe/thermos", __dir__)

if command == "thermos"
  load executable
else
  disable = ENV["DISABLE_THERMOS"]

  if (disable.nil? || disable.empty? || disable == "0") && !OpenHAB::Thermos.context
    ARGV.unshift(command)
    load executable
  end
end
