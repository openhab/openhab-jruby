# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "command_wrapper"

module OpenHAB
  module Thermos
    @commands = {}

    class << self
      attr_reader :commands

      def register_command(name, command = nil)
        raise ArgumentError, "Invalid command name: #{name}" unless name.match?(/\A[\w-]+\z/)

        commands[name] = CommandWrapper.new(name, command)
      end

      def command?(name)
        commands.include? name
      end

      def command(name)
        commands.fetch name
      end
    end
  end

  require_relative "commands/rspec"
  require_relative "commands/console"
end
