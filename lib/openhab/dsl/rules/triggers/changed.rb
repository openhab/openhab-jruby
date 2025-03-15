# frozen_string_literal: true

require_relative "conditions/duration"
require_relative "conditions/generic"
require_relative "trigger"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Creates changed triggers
        #
        class Changed < Trigger
          #
          # Create the trigger
          #
          # @param [Core::Items::Item, Core::Items::GroupItem::Members] item item to create trigger for
          # @param [Core::Types::State, Symbol, #===, nil] from state to restrict trigger to
          # @param [Core::Types::State, Symbol, #===, nil] to state to restrict trigger to
          # @param [Duration, Proc, nil] duration duration to delay trigger until to state is met
          # @param [Object] attach object to be attached to the trigger
          #
          # @return [org.openhab.core.automation.Trigger] openHAB triggers
          #
          def trigger(item:, from:, to:, duration:, attach:)
            if duration
              if logger.trace?
                item_name = item.respond_to?(:name) ? item.name : item.to_s
                logger.trace("Creating Changed Wait Change Trigger for Item(#{item_name}) Duration(#{duration}) " \
                             "To(#{to}) From(#{from}) Attach(#{attach})")
              end
              conditions = Conditions::Duration.new(to:, from:, duration:)
              label = NameInference.infer_rule_name_from_trigger(:changed,
                                                                 [item],
                                                                 from:,
                                                                 to:,
                                                                 duration:)

              changed_trigger(item:, from: nil, to: nil, attach:, conditions:, label:)
            else
              # swap from/to w/ nil if from/to need to be processed in Ruby
              # rubocop:disable Style/ParallelAssignment
              from_proc, from = from, nil unless Conditions.state?(from)
              to_proc, to = to, nil unless Conditions.state?(to)
              # rubocop:enable Style/ParallelAssignment
              conditions = Conditions::Generic.new(from: from_proc, to: to_proc) unless from_proc.nil? && to_proc.nil?
              changed_trigger(item:, from:, to:, attach:, conditions:)
            end
          end

          # @!visibility private
          # @return [String] An item state change trigger
          ITEM_STATE_CHANGE = "core.ItemStateChangeTrigger"

          private

          # @return [String] A thing status Change trigger
          THING_CHANGE = "core.ThingStatusChangeTrigger"
          private_constant :THING_CHANGE

          # @return [String] A group state change trigger for items in the group
          GROUP_STATE_CHANGE = "core.GroupStateChangeTrigger"
          private_constant :GROUP_STATE_CHANGE

          #
          # Create a changed trigger
          #
          # @param [Core::Items::Item, Core::Items::GroupItem::Members] item to create changed trigger on
          # @param [Core::Types::State, #===, nil] from state to restrict trigger to
          # @param [Core::Types::State, #===, nil] to state restrict trigger to
          # @param [Object] attach object to be attached to the trigger
          # @return [org.openhab.core.automation.Trigger]
          #
          def changed_trigger(item:, from:, to:, attach: nil, conditions: nil, label: nil)
            type, config = case item
                           when GroupItem::Members
                             group(group: item, from:, to:)
                           when Core::Things::Thing,
                                Core::Things::ThingUID
                             thing(thing: item, from:, to:)
                           when Core::Things::Registry
                             thing(thing: "*", from:, to:)
                           when Core::Items::Item
                             item(item:, from:, to:)
                           when Core::Items::Registry
                             item(item: "*", from:, to:)
                           else
                             if item.to_s.include?(":")
                               thing(thing: item, from:, to:)
                             else
                               item(item:, from:, to:)
                             end
                           end
            append_trigger(type:, config:, attach:, conditions:, label:)
          end

          #
          # Create a changed trigger for a thing
          #
          # @param [Core::Things::Thing] thing to detected changed states on
          # @param [String] from state to restrict trigger to
          # @param [String] to state to restrict trigger to
          #
          # @return [Array<Hash,String>] first element is a String specifying trigger type
          #  second element is a Hash configuring trigger
          #
          def thing(thing:, from:, to:)
            trigger_for_thing(thing:, type: THING_CHANGE, to:, from:)
          end

          #
          # Create a changed trigger for an item
          #
          # @param [Item] item to detected changed states on
          # @param [String] from state to restrict trigger to
          # @param [String] to to restrict trigger to
          #
          # @return [Array<Hash,String>] first element is a String specifying trigger type
          #  second element is a Hash configuring trigger
          #
          def item(item:, from:, to:)
            config = { "itemName" => item.is_a?(Item) ? item.name : item.to_s }
            config["state"] = to.to_s if to
            config["previousState"] = from.to_s if from
            [ITEM_STATE_CHANGE, config]
          end

          #
          # Create a changed trigger for group items
          #
          # @param [GroupItem] group to detected changed states on
          # @param [String] from state to restrict trigger to
          # @param [String] to to restrict trigger to
          #
          # @return [Array<Hash,String>] first element is a String specifying trigger type
          #  second element is a Hash configuring trigger
          #
          def group(group:, from:, to:)
            config = { "groupName" => group.name }
            config["state"] = to.to_s if to
            config["previousState"] = from.to_s if from
            [GROUP_STATE_CHANGE, config]
          end
        end
      end
    end
  end
end
