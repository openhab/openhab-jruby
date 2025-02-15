# frozen_string_literal: true

require_relative "numeric_item"
require_relative "switch_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.DimmerItem

      #
      # A DimmerItem can be used as a switch (ON/OFF), but it also accepts
      # percent values to reflect the dimmed state.
      #
      # @!attribute [r] state
      #   @return [PercentType, nil]
      #
      # @!attribute [r] was
      #   @return [PercentType, nil]
      #   @since openHAB 5.0
      #
      # @example
      #   DimmerOne << DimmerOne.state - 5
      #   DimmerOne << 100 - DimmerOne.state
      #
      # @example Turn on all dimmers in group
      #   Dimmers.members.each(&:on)
      #
      # @example Turn off all dimmers in group
      #    Dimmers.members.each(&:off)
      #
      # @example Turn on switches that are off
      #   Dimmers.select(&:off?).each(&:on)
      #
      # @example Turn off switches that are on
      #   Dimmers.select(&:on?).each(&:off)
      #
      # @example Dimmers can be selected in an enumerable with grep.
      #   items.grep(DimmerItem)
      #        .each { |dimmer| logger.info("#{dimmer.name} is a Dimmer") }
      #
      # @example Dimmers can also be used in case statements with ranges.
      #   items.grep(DimmerItem)
      #        .each do |dimmer|
      #     case dimmer.state
      #     when (0..50)
      #       logger.info("#{dimmer.name} is less than 50%")
      #     when (51..100)
      #       logger.info("#{dimmer.name} is greater than 50%")
      #     end
      #   end
      #
      # @example
      #   rule 'Dim a switch on system startup over 100 seconds' do
      #     on_load
      #     100.times do
      #       run { DimmerSwitch.dim }
      #       delay 1.second
      #     end
      #   end
      #
      # @example
      #   rule 'Dim a switch on system startup by 5, pausing every second' do
      #     on_load
      #     100.step(-5, 0) do |level|
      #       run { DimmerSwitch << level }
      #       delay 1.second
      #     end
      #   end
      #
      # @example
      #   rule 'Turn off any dimmers curently on at midnight' do
      #     every :day
      #     run do
      #       items.grep(DimmerItem)
      #            .select(&:on?)
      #            .each(&:off)
      #       end
      #   end
      #
      # @example
      #   rule 'Turn off any dimmers set to less than 50 at midnight' do
      #     every :day
      #     run do
      #       items.grep(DimmerItem)
      #            .select { |i| (1...50).cover?(i.state) }
      #            .each(&:off)
      #       end
      #   end
      #
      class DimmerItem < SwitchItem
        include NumericItem

        #
        # Dim the dimmer
        #
        # @param [Integer] amount to dim by
        #  If 1 is the amount, the DECREASE command is sent, otherwise the
        #  current state - amount is sent as a command.
        #
        # @return [Integer] level target for dimmer
        #
        # @example
        #   DimmerOne.dim
        #   DimmerOne.dim(2)
        #
        def dim(amount = 1)
          target = [state&.-(amount), 0].compact.max
          command!(target)
          target
        end

        #
        # Brighten the dimmer
        #
        # @param [Integer] amount to brighten by
        #   If 1 is the amount, the INCREASE command is sent, otherwise the
        # current state + amount is sent as a command.
        #
        # @return [Integer] level target for dimmer
        #
        # @example
        #   DimmerOne.brighten
        #   DimmerOne.brighten(2)
        #
        def brighten(amount = 1)
          target = [state&.+(amount), 100].compact.min
          command!(target)
          target
        end

        # @!method increase
        #   Send the {INCREASE} command to the item
        #   @return [DimmerItem] `self`

        # @!method decrease
        #   Send the {DECREASE} command to the item
        #   @return [DimmerItem] `self`

        # raw numbers translate directly to PercentType, not a DecimalType
        # @!visibility private
        def format_type(command)
          return Types::PercentType.new(command) if command.is_a?(Numeric)

          super
        end
      end
    end
  end
end

# @!parse DimmerItem = OpenHAB::Core::Items::DimmerItem
