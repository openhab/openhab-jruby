# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemStateEvent

      #
      # Helpers common to {ItemStateEvent} and {ItemStateChangedEvent}.
      #
      # Methods that refer to implicit conversion mean that for example
      # a PercentType of 100% will be `true` for {#on?}, etc.
      #
      module ItemState
        # @!method undef?
        #   Check if {#state} is {UNDEF}
        #   @return [true, false]

        # @!method null?
        #   Check if {#state} is {NULL}
        #   @return [true, false]

        # @!method on?
        #   Check if {#state} is (implicitly convertible to) {ON}
        #   @return [true, false]

        # @!method off?
        #   Check if {#state} is (implicitly convertible to) {OFF}
        #   @return [true, false]

        # @!method up?
        #   Check if {#state} is (implicitly convertible to) {UP}
        #   @return [true, false]

        # @!method down?
        #   Check if {#state} is (implicitly convertible to) {DOWN}
        #   @return [true, false]

        # @!method open?
        #   Check if {#state} is (implicitly convertible to) {OPEN}
        #   @return [true, false]

        # @!method closed?
        #   Check if {#state} is (implicitly convertible to) {CLOSED}
        #   @return [true, false]

        # @!method playing?
        #   Check if {#state} is {PLAY}
        #   @return [true, false]

        # @!method paused?
        #   Check if {#state} is {PAUSE}
        #   @return [true, false]

        #
        # Check if {#state} is defined (not {UNDEF} or {NULL})
        #
        # @return [true, false]
        #
        def state?
          !item_state.is_a?(UnDefType)
        end

        #
        # @!attribute [r] state
        # @return [State, nil] the state of the item if it is not {UNDEF} or {NULL}, `nil` otherwise.
        #
        def state
          item_state if state?
        end
      end

      # {AbstractEvent} sent when an item's state is updated (regardless of if it changed or not).
      class ItemStateEvent < ItemEvent
        include ItemState
      end
    end
  end
end
