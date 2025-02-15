# frozen_string_literal: true

require_relative "generic_item"
require_relative "numeric_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.RollershutterItem

      #
      # A {RollershutterItem} allows the control of roller shutters, i.e.
      # moving them up, down, stopping or setting it to close to a certain
      # percentage.
      #
      # @!attribute [r] state
      #   @return [PercentType, UpDownType, nil]
      #
      # @!attribute [r] was
      #   @return [PercentType, UpDownType, nil]
      #   @since openHAB 5.0
      #
      # @example Roll up all Rollershutters in a group
      #   Shutters.up
      #
      # @example Log a warning for all rollershutters that are not up
      #   Shutters.reject(&:up?).each do |item|
      #     logger.warn("#{item.name} is not rolled up!")
      #   end
      #
      # @example Set rollershutter to a specified position
      #   Example_Rollershutter << 40
      class RollershutterItem < GenericItem
        include NumericItem

        # @!method up?
        #   Check if the item state == {UP}
        #   @return [true,false]

        # @!method down?
        #   Check if the item state == {DOWN}
        #   @return [true,false]

        # @!method was_up?
        #   Check if {#was} is {UP}
        #   @return [true, false]

        # @!method was_down?
        #   Check if {#was} is {DOWN}
        #   @return [true, false]

        # @!method up
        #   Send the {UP} command to the item
        #   @return [RollershutterItem] `self`

        # @!method up!
        #   Send the {UP} command to the item, even when {OpenHAB::DSL.ensure_states! ensure_states!} is in effect.
        #   @return [RollershutterItem] `self`

        # @!method down
        #   Send the {DOWN} command to the item
        #   @return [RollershutterItem] `self`

        # @!method down!
        #   Send the {DOWN} command to the item, even when {OpenHAB::DSL.ensure_states! ensure_states!} is in effect.
        #   @return [RollershutterItem] `self`

        # @!method stop
        #   Send the {STOP} command to the item
        #   @return [RollershutterItem] `self`

        # @!method move
        #   Send the {MOVE} command to the item
        #   @return [RollershutterItem] `self`

        # raw numbers translate directly to PercentType, not a DecimalType
        # @!visibility private
        def format_type(command)
          return Types::PercentType.new(command) if command.is_a?(Numeric)

          super
        end
      end
    end
  end
end

# @!parse RollershutterItem = OpenHAB::Core::Items::RollershutterItem
