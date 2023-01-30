# frozen_string_literal: true

require_relative "percent_type"

require_relative "type"

module OpenHAB
  module Core
    module Types
      HSBType = org.openhab.core.library.types.HSBType

      # {HSBType} is a complex type with constituents for hue, saturation and
      #  brightness and can be used for color items.
      class HSBType < PercentType
        # @!constant BLACK
        #   @return [HSBType]
        # @!constant WHITE
        #   @return [HSBType]
        # @!constant RED
        #   @return [HSBType]
        # @!constant GREEN
        #   @return [HSBType]
        # @!constant BLUE
        #   @return [HSBType]

        # conversion to QuantityType doesn't make sense on HSBType
        undef_method :|

        remove_method :==

        # r, g, b as an array of symbols
        RGB_KEYS = %i[r g b].freeze
        private_constant :RGB_KEYS

        class << self
          # @!method from_rgb(r, g, b)
          #   Create HSBType from RGB values
          #   @param r [Integer] Red component (0-255)
          #   @param g [Integer] Green component (0-255)
          #   @param b [Integer] Blue component (0-255)
          #   @return [HSBType]

          # @!method from_xy(x, y)
          #   Create HSBType representing the provided xy color values in CIE XY color model
          #   @param x [Float]
          #   @param y [Float]
          #   @return [HSBType]

          # Create HSBType from hue, saturation, and brightness values
          # @param hue [DecimalType, QuantityType, Numeric] Hue component (0-360º)
          # @param saturation [PercentType, Numeric] Saturation component (0-100%)
          # @param brightness [PercentType, Numeric] Brightness component (0-100%)
          # @return [HSBType]
          def from_hsb(hue, saturation, brightness)
            new(hue, saturation, brightness)
          end

          # add additional "overloads" to the constructor
          # @!visibility private
          def new(*args)
            if args.length == 1 && args.first.respond_to?(:to_str)
              value = args.first.to_str

              # parse some formats openHAB doesn't understand
              # in this case, HTML hex format for rgb
              if (match = value.match(/^#(\h{2})(\h{2})(\h{2})$/))
                rgb = match.to_a[1..3].map { |v| v.to_i(16) }
                logger.trace("creating from rgb #{rgb.inspect}")
                return from_rgb(*rgb)
              end
            end

            # Convert strings using java class
            return value_of(args.first) if args.length == 1 && args.first.is_a?(String)

            # use super constructor for empty args
            return super unless args.length == 3

            # convert from several numeric-like types to the exact types
            # openHAB needs
            hue = args[0]
            args[0] = if hue.is_a?(DecimalType)
                        hue
                      elsif hue.is_a?(QuantityType)
                        DecimalType.new(hue.to_unit(Units::DEGREE_ANGLE).to_big_decimal)
                      elsif hue.respond_to?(:to_d)
                        DecimalType.new(hue)
                      end
            args[1..2] = args[1..2].map do |v|
              if v.is_a?(PercentType)
                v
              elsif v.respond_to?(:to_d)
                PercentType.new(v)
              end
            end

            super(*args)
          end
        end

        #
        # Comparison
        #
        # @param [NumericType, Numeric]
        #   other object to compare to
        #
        # @return [Integer, nil] -1, 0, +1 depending on whether `other` is
        #   less than, equal to, or greater than self
        #
        #   `nil` is returned if the two values are incomparable.
        #
        def <=>(other)
          logger.trace("(#{self.class}) #{self} <=> #{other} (#{other.class})")
          if other.is_a?(HSBType)
            [brightness, hue, saturation] <=> [other.brightness, other.hue, other.saturation]
          else
            super
          end
        end

        # rename raw methods so we can overwrite them
        # @!visibility private
        alias_method :raw_hue, :hue

        # @!attribute [r] hue
        # @return [QuantityType] The color's hue component as a {QuantityType} of unit DEGREE_ANGLE.
        def hue
          QuantityType.new(raw_hue.to_big_decimal, Units::DEGREE_ANGLE)
        end

        # Convert to a packed 32-bit RGB value representing the color in the default sRGB color model.
        #
        # The alpha component is always 100%.
        #
        # @return [Integer]
        alias_method :argb, :rgb

        # Convert to a packed 24-bit RGB value representing the color in the default sRGB color model.
        # @return [Integer]
        def rgb
          argb & 0xffffff
        end

        # Convert to an HTML-style string of 6 hex characters in the default sRGB color model.
        # @return [String] `"#xxxxxx"`
        def to_hex
          Kernel.format("#%06x", rgb)
        end

        # include units
        # @!visibility private
        def to_s
          "#{hue},#{saturation},#{brightness}"
        end

        # @!attribute [r] saturation
        #   @return [PercentType]

        # @!attribute [r] brightness
        #   @return [PercentType]

        # @!attribute [r] red
        #   @return [PercentType]

        # @!attribute [r] green
        #   @return [PercentType]

        # @!attribute [r] blue
        #   @return [PercentType]

        # @!method to_rgb
        # Convert to RGB values representing the color in the default sRGB color model
        # @return [[PercentType, PercentType, PercentType]]

        # @!method to_xy
        #   Convert to the xyY values representing this object's color in CIE XY color model
        #   @return [[PercentType, PercentType, PercentType]]
      end
    end
  end
end

# @!parse HSBType = OpenHAB::Core::Types::HSBType
