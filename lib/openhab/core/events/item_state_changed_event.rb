# frozen_string_literal: true

require_relative "item_state_event"

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemStateChangedEvent

      #
      # {AbstractEvent} sent when an item's state has changed.
      #
      class ItemStateChangedEvent < ItemEvent
        include ItemState

        # @!attribute [r] last_state_update
        #   @return [ZonedDateTime] the time the previous state update occurred
        #   @since openHAB 5.0

        # @!attribute [r] last_state_change
        #   @return [ZonedDateTime] the time the previous state change occurred
        #   @since openHAB 5.0

        # @!method was_undef?
        #   Check if {#was} is {UNDEF}
        #   @return [true, false]

        # @!method was_null?
        #   Check if {#was} is {NULL}
        #   @return [true, false]

        # @!method was_on?
        #   Check if {#was} is (implicitly convertible to) {ON}
        #   @return [true, false]

        # @!method was_off?
        #   Check if {#was} is (implicitly convertible to) {OFF}
        #   @return [true, false]

        # @!method was_up?
        #   Check if {#was} is (implicitly convertible to) {UP}
        #   @return [true, false]

        # @!method was_down?
        #   Check if {#was} is (implicitly convertible to) {DOWN}
        #   @return [true, false]

        # @!method was_open?
        #   Check if {#was} is (implicitly convertible to) {OPEN}
        #   @return [true, false]

        # @!method was_closed?
        #   Check if {#was} is (implicitly convertible to) {CLOSED}
        #   @return [true, false]

        # @!method was_playing?
        #   Check if {#was} is {PLAY}
        #   @return [true, false]

        # @!method was_paused?
        #   Check if {#was} is {PAUSE}
        #   @return [true, false]

        #
        # Check if state was defined (not {UNDEF} or {NULL})
        #
        # @return [true,false]
        #
        def was?
          !old_item_state.is_a?(UnDefType)
        end

        #
        # @!attribute [r] was
        # @return [State, nil] the prior state of the item if it was not {UNDEF} or {NULL}, `nil` otherwise.
        #
        def was
          old_item_state if was?
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Events::ItemStateChangedEvent item=#{item_name} " \
              "state=#{item_state.inspect} was=#{old_item_state.inspect}"
          # @deprecated OH4.3 remove respond_to? checks in the next two lines when dropping OH 4.3
          s += " last_state_update=#{last_state_update}" if respond_to?(:last_state_update) && last_state_update
          s += " last_state_change=#{last_state_change}" if respond_to?(:last_state_change) && last_state_change
          s += " source=#{source.inspect}" if source
          "#{s}>"
        end
      end
    end
  end
end
