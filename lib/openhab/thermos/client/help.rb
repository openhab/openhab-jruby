# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    module Client
      class Help < Command
        attr_reader :client_commands, :user_commands

        class << self
          def description = "Print available commands."

          def call(args)
            require_relative "../commands"
            super
          end
        end

        def initialize(args, client_commands = nil, user_commands = nil)
          super(args)

          @client_commands = client_commands || Client::COMMANDS.dup
          @user_commands = user_commands || Thermos.commands.dup

          @client_commands.delete_if { |k, _| k.start_with?("-") }
        end

        def call
          puts formatted_help
        end

        def formatted_help
          ["Version: #{env.version}\n",
           "Usage: thermos COMMAND [ARGS]\n",
           *command_help("the runtime", client_commands),
           "",
           *command_help("your project", user_commands)].join("\n")
        end

        def command_help(subject, commands)
          ["Commands for #{subject}:\n",
           *commands.sort_by(&:first).filter_map { |name, command| display(name, command) }]
        end

        private

        def all_commands
          client_commands.merge(user_commands)
        end

        def display(name, command)
          "  #{name.ljust(max_name_width)}  #{command.description}" if command.description
        end

        def max_name_width
          @max_name_width ||= all_commands.keys.map(&:length).max
        end
      end
    end
  end
end
