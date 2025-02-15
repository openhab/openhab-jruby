# frozen_string_literal: true

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.CallItem

      #
      #  A {CallItem} identifies a telephone call by its origin and destination.
      #
      # @!attribute [r] state
      #   @return [StringListType, nil]
      #
      # @!attribute [r] was
      #   @return [StringListType, nil]
      #   @since openHAB 5.0
      #
      class CallItem < GenericItem
        # @!visibility private
        def format_type(command)
          return command if command.is_a?(Types::StringListType)
          return Types::StringListType.new(command.to_ary.map(&:to_s)) if command.respond_to?(:to_ary)

          super
        end
      end
    end
  end
end

# @!parse CallItem = OpenHAB::Core::Items::CallItem
