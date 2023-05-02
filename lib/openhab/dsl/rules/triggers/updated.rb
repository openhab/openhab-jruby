# frozen_string_literal: true

require_relative "trigger"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Creates updated triggers
        #
        class Updated < Trigger
          #
          # Create the trigger
          #
          # @param [Object] item item to create trigger for
          # @param [Core::Types::State, Symbol, #===, nil] to state to restrict trigger to
          # @param [Object] attach object to be attached to the trigger
          #
          # @return [org.openhab.core.automation.Trigger]
          #
          def trigger(item:, to:, attach:)
            unless Conditions.state?(to)
              conditions = Conditions::Generic.new(to: to)
              to = nil
            end

            type, config = case item
                           when GroupItem::Members
                             group_update(item: item, to: to)
                           when Core::Things::Thing,
                 Core::Things::ThingUID
                             thing_update(thing: item, to: to)
                           else
                             item_update(item: item, to: to)
                           end
            append_trigger(type: type, config: config, attach: attach, conditions: conditions)
          end

          private

          # @return [String] A thing status update trigger
          THING_UPDATE = "core.ThingStatusUpdateTrigger"
          private_constant :THING_UPDATE

          # @return [String] An item state update trigger
          ITEM_STATE_UPDATE = "core.ItemStateUpdateTrigger"
          private_constant :ITEM_STATE_UPDATE

          # @return [String] A group state update trigger for items in the group
          GROUP_STATE_UPDATE = "core.GroupStateUpdateTrigger"
          private_constant :GROUP_STATE_UPDATE

          #
          # Create an update trigger for an item
          #
          # @param [Item] item to create trigger for
          # @param [State] to optional state restriction for target
          #
          # @return [Array<Hash,String>] first element is a String specifying trigger type
          #  second element is a Hash configuring trigger
          #
          def item_update(item:, to:)
            config = { "itemName" => item.name }
            config["state"] = to.to_s unless to.nil?
            [ITEM_STATE_UPDATE, config]
          end

          #
          # Create an update trigger for a group
          #
          # @param [GroupItem::Members] item to create trigger for
          # @param [State] to optional state restriction for target
          #
          # @return [Array<Hash,String>] first element is a String specifying trigger type
          #  second element is a Hash configuring trigger
          #
          def group_update(item:, to:)
            config = { "groupName" => item.group.name }
            config["state"] = to.to_s unless to.nil?
            [GROUP_STATE_UPDATE, config]
          end

          #
          # Create an update trigger for a thing
          #
          # @param [Thing] thing to create trigger for
          # @param [State] to optional state restriction for target
          #
          # @return [Array<Hash,String>] first element is a String specifying trigger type
          #  second element is a Hash configuring trigger
          #
          def thing_update(thing:, to:)
            trigger_for_thing(thing: thing, type: THING_UPDATE, to: to)
          end
        end
      end
    end
  end
end
