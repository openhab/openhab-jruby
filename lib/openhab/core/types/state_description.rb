# frozen_string_literal: true

module OpenHAB
  module Core
    module Types
      StateDescription = org.openhab.core.types.StateDescription

      # Describes restrictions of an item state and gives information how to interpret it
      class StateDescription
        # @!attribute [r] step
        #   @return [BigDecimal, nil]

        # @!attribute [r] pattern
        #   @return [String, nil]

        # @!attribute [r] read_only?
        #   @return [true, false]

        # @!attribute [r] options
        #   @return [Array<org.openhab.core.types.StateOption>]

        # @!attribute [r] range
        # @return [Range, nil]
        def range
          return nil unless minimum || maximum

          minimum..maximum
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Types::StateDescription"
          r = range
          s += " read_only" if read_only?
          s += " range=#{r}" if r
          s += " step=#{step}" if step
          s += " pattern=#{pattern.inspect}" if pattern && !pattern.empty?
          unless options.empty?
            s += " options=["
            options.each_with_index do |o, i|
              s += ", " if i != 0

              s += o.value.inspect

              s += " (#{o.label.inspect})" if o.value != o.label && !o.label.nil?
            end
            s += "]"
          end
          "#{s}>"
        end
      end
    end
  end
end
