# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "client/command"
require_relative "client/run"
require_relative "client/help"
require_relative "client/binstub"
require_relative "client/server"
require_relative "client/status"
require_relative "client/stop"
require_relative "client/version"

module OpenHAB
  module Thermos
    # Dispatches administrative and user commands.
    # @!visibility private
    module Client
      COMMANDS = {
        "help" => Help,
        "-h" => Help,
        "--help" => Help,
        "binstub" => Binstub,
        "stop" => Stop,
        "status" => Status,
        "-v" => Version,
        "--version" => Version,
        "server" => Server,
        "version" => Version
      }.freeze

      module_function

      def command_for(name)
        COMMANDS[name] || Run
      end

      def run(args = ARGV)
        command_for(args.first).call(args)
      rescue ArgumentError, ClientError, UnknownProject => e
        warn e.message
        exit 1
      end
    end
  end
end
