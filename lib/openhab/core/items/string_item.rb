# frozen_string_literal: true

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.StringItem

      #
      # A {StringItem} can be used for any kind of string to either send or
      # receive from a device.
      #
      # @!attribute [r] state
      #   @return [StringType, nil]
      #
      # @!attribute [r] was
      #   @return [StringType, nil]
      #   @since openHAB 5.0
      #
      # @example
      #   # StringOne has a current state of "Hello"
      #   StringOne << StringOne + " World!"
      #   # StringOne will eventually have a state of 'Hello World!'
      #
      class StringItem < GenericItem
      end
    end
  end
end

# @!parse StringItem = OpenHAB::Core::Items::StringItem
