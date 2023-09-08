# frozen_string_literal: true

require_relative "type"

module OpenHAB
  module Core
    module Types
      UpDownType = org.openhab.core.library.types.UpDownType

      #
      # Implements the {UP} and {DOWN} commands.
      #
      # Also, {PercentType} can be converted to {UpDownType}
      # for more semantic comparisons. `0` is {UP}, `100` is
      # {DOWN}, and anything in-between is neither.
      #
      class UpDownType
        # @!parse include Command, State

        # @!constant UP
        #   Up Command/State
        # @!constant DOWN
        #   Down Command/State

        # @!method up?
        #   Check if `self == UP`
        #   @return [true,false]

        # @!method down?
        #   Check if `self == DOWN`
        #   @return [true,false]

        #
        # Invert the type
        #
        # @return [UpDownType] {UP} if {down?}, {DOWN} if {up?}
        #
        def !
          return UP if down?

          DOWN if up?
        end
      end
    end
  end
end

# @!parse
#   UpDownType = OpenHAB::Core::Types::UpDownType
#   UP = OpenHAB::Core::Types::UpDownType::UP
#   DOWN = OpenHAB::Core::Types::UpDownType::DOWN
