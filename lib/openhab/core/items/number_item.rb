# frozen_string_literal: true

require_relative "generic_item"
require_relative "numeric_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.NumberItem

      #
      # A NumberItem has a decimal value and is usually used for all kinds
      # of sensors, like temperature, brightness, wind, etc.
      # It can also be used as a counter or as any other thing that can be expressed
      # as a number.
      #
      # Non-dimensioned numbers will have a state of {DecimalType}, while
      # dimensioned numbers will have a state of {QuantityType}. Be sure
      # to read the documentation for those two classes for how to work with
      # the different states of a {NumberItem}.
      #
      # @!attribute [r] dimension
      #   @return [Class, nil] The dimension of the number item.
      # @!attribute [r] unit
      #   @return [javax.measure.Unit, nil]
      # @!attribute [r] state
      #   @return [DecimalType, QuantityType, nil]
      # @!attribute [r] was
      #   @return [DecimalType, QuantityType, nil]
      #   @since openHAB 5.0
      #
      # @example Number Items can be selected in an enumerable with grep.
      #   # Get all NumberItems
      #   items.grep(NumberItem)
      #        .each { |number| logger.info("#{item.name} is a Number Item") }
      #
      class NumberItem < GenericItem
        include NumericItem

        # raw numbers translate directly to {DecimalType}, not a string
        # @!visibility private
        def format_type(command)
          if command.is_a?(Numeric)
            if unit && (target_unit = DSL.unit(unit.dimension) || unit)
              return Types::QuantityType.new(command, target_unit)
            end

            return Types::DecimalType.new(command)
          end

          super
        end

        # @!visibility private
        def config_eql?(other)
          super && dimension == other.dimension
        end

        # @!attribute [r] range
        # Returns the range of values allowed for this item, as defined by its
        # state description.
        #
        # If this item has a {#unit}, it will be applied to the result, returning
        # a range of {QuantityType} instead of BigDecimal.
        # @return [Range, nil]
        # @note State descriptions can be provided by bindings, defined in
        #   metadata, or theoretically come from other sources.
        def range
          return unless (sd = state_description)

          # check if we have a unit, even if the item's metadata doesn't declare
          # it properly
          unit = self.unit || ((s = state) && s.is_a?(QuantityType) && s.unit)
          min = sd.minimum&.to_d
          max = sd.maximum&.to_d
          return nil unless min || max

          min |= unit if min && unit
          max |= unit if max && unit
          min..max
        end

        protected

        # Adds the unit dimension
        def type_details
          ":#{dimension}" if dimension
        end
      end
    end
  end
end

# @!parse NumberItem = OpenHAB::Core::Items::NumberItem
