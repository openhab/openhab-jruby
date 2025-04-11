# frozen_string_literal: true

require_relative "dimmer_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.ColorItem

      #
      # {ColorItem} represents a color values, e.g. for LED lights.
      #
      # Note that it inherits from {DimmerItem}, so you can call {#on}, {#off},
      # {#on?}, {#off?}, etc. on it. Its state type is an {HSBType},
      # which is stored as Hue, Saturation, and Brightness, but has easy
      # helpers for working with RGB values of various forms.
      #
      # @example Sending commands
      #   HueBulb << "#ff0000" # send 'red' as a command
      #   HueBulb.on
      #   HueBulb.dim
      #
      # @example Inspect state
      #   HueBulb.on? # => true
      #   HueBulb.state.red # => 100%
      #   HueBulb.state.hue # => 0 °
      #   HueBulb.state.brightness # => 100%
      #   HueBulb.state.to_rgb # => [100%, 0%, 0%]
      #   HueBulb.state.rgb # => 16711680
      #   HueBulb.state.to_hex # => "0xff0000"
      #   HueBulb.state.on? # => true
      #   HueBulb.state.red.to_byte # => 255
      #   HueBulb.state.blue.to_byte # => 0
      #
      # @!attribute [r] state
      #   @return [HSBType, nil]
      #
      # @!attribute [r] was
      #   @return [HSBType, nil]
      #   @since openHAB 5.0
      #
      class ColorItem < DimmerItem
        # Make sure to do the String => HSBType conversion in Ruby,
        # where we add support for hex
        # @!visibility private
        def format_type(type)
          return Types::HSBType.new(type) if type.respond_to?(:to_str)

          super
        end
      end
    end
  end
end

# @!parse ColorItem = OpenHAB::Core::Items::ColorItem
