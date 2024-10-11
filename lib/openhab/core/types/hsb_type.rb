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
        if OpenHAB::Core.version >= OpenHAB::Core::V4_0
          java_import org.openhab.core.util.ColorUtil
          private_constant :ColorUtil
        end

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
                logger.trace { "creating from rgb #{rgb.inspect}" }
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

          # Create HSBType from a color temperature
          # @param cct [QuantityType, Number] The color temperature (assumed in Kelvin, if not a QuantityType)
          # @return [HSBType]
          # @since openHAB 4.3
          def from_cct(cct)
            from_xy(*ColorUtil.kelvin_to_xy((cct | "K").double_value))
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
          logger.trace { "(#{self.class}) #{self} <=> #{other} (#{other.class})" }
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

        # @!attribute [r] cct
        # @return [QuantityType] The correlated color temperature in Kelvin
        # @since openHAB 4.3
        # @see https://en.wikipedia.org/wiki/Planckian_locus Planckian Locus
        def cct
          ColorUtil.xy_to_kelvin(to_xy[0..1].map { |x| x.double_value / 100 }) | "K"
        end

        # @!attribute [r] duv
        #   The distance that this color is from the planckian locus
        #
        # @return [Float] The delta u, v
        #
        # @see planckian?
        # @see planckian_cct
        # @see https://en.wikipedia.org/wiki/Planckian_locus Planckian Locus
        # @since openHAB 4.3
        def duv
          ColorUtil.xy_to_duv(to_xy[0..1].map { |x| x.double_value / 100 })
        end

        # Checks if this color is within a certain tolerance of the planckian locus
        #
        # @param [Float] duv_tolerance The maximum allowed distance from the planckian locus
        # @param [Numeric, PercentType] maximum_saturation The maximum allowed saturation.
        #   Some colors (bright green for example) may be close to the planckian locus,
        #   but you don't want to treat them as "white" because they are very saturated.
        # @return [true, false]
        #
        # @note The parameters and defaults for this method are subject to change in future
        #   releases of this library, and should be considered beta. For now, the default
        #   parameters should be sufficient to detect most colors that Apple's HomeKit color
        #   temperature color chooser uses as planckian, without detecting most other "real"
        #   colors as planckian.
        # @see duv
        # @see planckian_cct
        # @see https://en.wikipedia.org/wiki/Planckian_locus Planckian Locus
        # @since openHAB 4.3
        def planckian?(duv_tolerance: 0.015, maximum_saturation: 75)
          duv.abs < duv_tolerance && saturation < maximum_saturation
        end

        # Returns the color temperature of this color _if_ it is within a certain tolerance
        # of the planckian locus.
        #
        # @param [Range, NumberItem] range An allowed range to additionally restrict
        #   if the CCT should be returned. A NumberItem that represents a CCT channel
        #   may be provided, and {NumberItem#range NumberItem#Range} will be used instead. If the range
        #   does not have units (is {QuantityType}), it should be in Kelvin.
        # @return [QuantityType, nil] The color temperature in Kelvin
        #   (unless the range is in mireds; then it will be in mireds)
        #
        # @note Additional parameters are forwarded to {#planckian?}
        # @see planckian?
        # @see https://en.wikipedia.org/wiki/Planckian_locus Planckian Locus
        # @since openHAB 4.3
        def planckian_cct(range: nil, **kwargs)
          return unless planckian?(**kwargs)

          range = range.range if range.is_a?(NumberItem)
          cct = self.cct
          if range
            range_type = range.begin || range.end
            if !range_type.is_a?(QuantityType)
              range = Range.new(range.begin | "K", range.end | "K")
            elsif range_type.unit.to_s == "mired"
              cct |= "mired"
            end
          end
          return nil if range && !range.cover?(cct)

          cct
        end
      end
    end
  end
end

# @!parse HSBType = OpenHAB::Core::Types::HSBType
