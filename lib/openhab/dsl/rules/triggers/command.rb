# frozen_string_literal: true

require_relative "trigger"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Creates command triggers
        #
        class Command < Trigger
          #
          # Create a received command trigger
          #
          # @param [Object] item item to create trigger for
          # @param [Core::Types::State, Symbol, #===, nil] command to check against
          # @param [Object] attach object to be attached to the trigger
          #
          # @return [org.openhab.core.automation.Trigger]
          #
          def trigger(item:, command:, attach:)
            unless Conditions.state?(command)
              conditions = Conditions::Generic.new(command: command)
              command = nil
            end

            type, config = if item.is_a?(GroupItem::Members)
                             [GROUP_COMMAND, { "groupName" => item.group.name }]
                           else
                             [ITEM_COMMAND, { "itemName" => item.name }]
                           end
            config["command"] = command.to_s unless command.nil?
            append_trigger(type: type, config: config, attach: attach, conditions: conditions)
          end

          # @return [String] item command trigger
          ITEM_COMMAND = "core.ItemCommandTrigger"

          # @return [String] A group command trigger for items in the group
          GROUP_COMMAND = "core.GroupCommandTrigger"
          private_constant :GROUP_COMMAND
        end
      end
    end
  end
end
