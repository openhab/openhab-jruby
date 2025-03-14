# frozen_string_literal: true

module OpenHAB
  module Core
    module Types
      CommandDescription = org.openhab.core.types.CommandDescription

      # Describes commands you can send to an item
      module CommandDescription
        # @!attribute [r] options
        # @return [Array<org.openhab.core.types.CommandOption>]
        def options
          command_options
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Types::CommandDescription options=["
          command_options.each_with_index do |o, i|
            s += ", " if i != 0

            s += o.command.inspect

            s += " (#{o.label.inspect})" if o.command != o.label && !o.label.nil?
          end
          s += "]>"
        end
      end
    end
  end
end
