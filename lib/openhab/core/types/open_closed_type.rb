# frozen_string_literal: true

require_relative "type"

module OpenHAB
  module Core
    module Types
      OpenClosedType = org.openhab.core.library.types.OpenClosedType

      # Implements {OPEN} and {CLOSED} states.
      class OpenClosedType
        # @!parse include State

        # @!constant OPEN
        #   Open State
        # @!constant CLOSED
        #   Closed State

        # @!method open?
        #   Check if `self == OPEN`
        #   @return [true,false]

        # @!method closed?
        #   Check if `self == CLOSED`
        #   @return [true,false]

        # Invert the type
        # @return [OpenClosedType] {OPEN} if {closed?}, {CLOSED} if {open?}
        def !
          return CLOSED if open?

          OPEN if closed?
        end
      end
    end
  end
end

# @!parse
#   OpenClosedType = OpenHAB::Core::Types::OpenClosedType
#   OPEN = OpenHAB::Core::Types::OpenClosedType::OPEN
#   CLOSED = OpenHAB::Core::Types::OpenClosedType::CLOSED
