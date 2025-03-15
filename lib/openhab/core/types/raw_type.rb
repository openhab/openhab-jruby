# frozen_string_literal: true

require_relative "type"

module OpenHAB
  module Core
    module Types
      RawType = org.openhab.core.library.types.RawType

      #
      # This type can be used for all binary data such as images, documents, sounds etc.
      #
      class RawType
        # @!parse include State

        # @attribute [r] mime_type
        #   @return [String]

        # @attribute[r] bytes
        #   @return [byte[]]

        # @attribute [r] bytesize
        # @return [Integer]
        def bytesize
          bytes.size
        end
      end
    end
  end
end

# @!parse RawType = OpenHAB::Core::Types::RawType
