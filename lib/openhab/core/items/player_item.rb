# frozen_string_literal: true

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.PlayerItem

      # Adds methods to core OpenHAB NumberItem type to make it more natural in
      # Ruby
      class PlayerItem < GenericItem
        # @!method play?
        #   Check if the item state == `PLAYING`
        #   @return [true,false]

        # @!method paused?
        #   Check if the item state == `PAUSED`
        #   @return [true,false]

        # @!method rewinding?
        #   Check if the item state == `REWIND`
        #   @return [true,false]

        # @!method fast_forwarding?
        #   Check if the item state == `FASTFORWARD`
        #   @return [true,false]

        # @!method play
        #   Send the `PLAY` command to the item
        #   @return [PlayerItem] `self`

        # @!method pause
        #   Send the `PAUSE` command to the item
        #   @return [PlayerItem] `self`

        # @!method rewind
        #   Send the `REWIND` command to the item
        #   @return [PlayerItem] `self`

        # @!method fast_forward
        #   Send the `FASTFORWARD` command to the item
        #   @return [PlayerItem] `self`

        # @!method next
        #   Send the `NEXT` command to the item
        #   @return [PlayerItem] `self`

        # @!method previous
        #   Send the `PREVIOUS` command to the item
        #   @return [PlayerItem] `self`
      end
    end
  end
end