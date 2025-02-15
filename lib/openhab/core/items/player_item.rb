# frozen_string_literal: true

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.PlayerItem

      #
      # A {PlayerItem} allows control of a player, e.g. an audio player.
      #
      # @example Start playing on a player item
      #   Chromecast.play
      # @example Check if a player is paused
      #   logger.warn("#{item.name} is paused") if Chromecast.paused?
      #
      # @!attribute [r] state
      #   @return [PlayPauseType, RewindFastforwardType, nil]
      #
      # @!attribute [r] was
      #   @return [PlayPauseType, RewindFastforwardType, nil]
      #   @since openHAB 5.0
      #
      # @!method play?
      #   Check if the item state == {PLAY}
      #   @return [true,false]
      #
      # @!method paused?
      #   Check if the item state == {PAUSE}
      #   @return [true,false]
      #
      # @!method rewinding?
      #   Check if the item state == {REWIND}
      #   @return [true,false]
      #
      # @!method fast_forwarding?
      #   Check if the item state == {FASTFORWARD}
      #   @return [true,false]
      #
      # @!method was_playing?
      #   Check if {#was} is {PLAY}
      #   @return [true, false]
      #
      # @!method was_paused?
      #   Check if {#was} is {PAUSE}
      #   @return [true, false]
      #
      # @!method was_rewinding?
      #   Check if {#was} is {REWIND}
      #   @return [true, false]
      #
      # @!method was_fast_forwarding?
      #   Check if {#was} is {FASTFORWARD}
      #   @return [true, false]
      #
      # @!method play
      #   Send the {PLAY} command to the item
      #   @return [PlayerItem] `self`
      #
      # @!method play!
      #   Send the {PLAY} command to the item, even when {OpenHAB::DSL.ensure_states! ensure_states!} is in effect.
      #   @return [PlayerItem] `self`
      #
      # @!method pause
      #   Send the {PAUSE} command to the item
      #   @return [PlayerItem] `self`
      #
      # @!method pause!
      #   Send the {PAUSE} command to the item, even when {OpenHAB::DSL.ensure_states! ensure_states!} is in effect.
      #   @return [PlayerItem] `self`
      #
      # @!method rewind
      #   Send the {REWIND} command to the item
      #   @return [PlayerItem] `self`
      #
      # @!method rewind!
      #   Send the {REWIND} command to the item, even when {OpenHAB::DSL.ensure_states! ensure_states!} is in effect.
      #   @return [PlayerItem] `self`
      #
      # @!method fast_forward
      #   Send the {FASTFORWARD} command to the item
      #   @return [PlayerItem] `self`
      #
      # @!method fast_forward!
      #   Send the {FASTFORWARD} command to the item, even when
      #     {OpenHAB::DSL.ensure_states! ensure_states!} is in effect.
      #   @return [PlayerItem] `self`
      #
      # @!method next
      #   Send the {NEXT} command to the item
      #   @return [PlayerItem] `self`
      #
      # @!method previous
      #   Send the {PREVIOUS} command to the item
      #   @return [PlayerItem] `self`
      #
      class PlayerItem < GenericItem
      end
    end
  end
end

# @!parse PlayerItem = OpenHAB::Core::Items::PlayerItem
