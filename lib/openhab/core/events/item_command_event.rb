# frozen_string_literal: true

require_relative "item_event"

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemCommandEvent

      # {AbstractEvent} sent when an item receives a command.
      class ItemCommandEvent < ItemEvent
        # @!attribute [r] command
        # @return [Command] The command sent to the item.
        alias_method :command, :item_command

        # @!method refresh?
        #   Check if {#command} is {REFRESH}
        #   @return [true, false]

        # @!method on?
        #   Check if {#command} is (implicitly convertible to) {ON}
        #   @return [true, false]

        # @!method off?
        #   Check if {#command} is (implicitly convertible to) {OFF}
        #   @return [true, false]

        # @!method up?
        #   Check if {#command} is (implicitly convertible to) {UP}
        #   @return [true, false]

        # @!method down?
        #   Check if {#command} is (implicitly convertible to) {DOWN}
        #   @return [true, false]

        # @!method stop?
        #   Check if {#command} is {STOP}
        #   @return [true, false]

        # @!method move?
        #   Check if {#command} is {MOVE}
        #   @return [true, false]

        # @!method increase?
        #   Check if {#command} is {INCREASE}
        #   @return [true, false]

        # @!method decrease?
        #   Check if {#command} is {DECREASE}
        #   @return [true, false]

        # @!method play?
        #   Check if {#command} is {PLAY}
        #   @return [true, false]

        # @!method pause?
        #   Check if {#command} is {PAUSE}
        #   @return [true, false]

        # @!method rewind?
        #   Check if {#command} is {REWIND}
        #   @return [true, false]

        # @!method fast_forward?
        #   Check if {#command} is {FASTFORWARD}
        #   @return [true, false]

        # @!method next?
        #   Check if {#command} is {NEXT}
        #   @return [true, false]

        # @!method previous?
        #   Check if {#command} is {PREVIOUS}
        #   @return [true, false]
      end
    end
  end
end
