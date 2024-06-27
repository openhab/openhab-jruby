# frozen_string_literal: true

require "forwardable"

require_relative "type"

module OpenHAB
  module Core
    module Types
      StringListType = org.openhab.core.library.types.StringListType

      # {StringListType} can be used for items that are dealing with telephony functionality.
      #
      # The entries can be accessed like an array.
      #
      # @example
      #   string_list = StringListType.new("a", "b", "c")
      #   logger.info "first entry: #{string_list.first}" # => "a"
      #   logger.info "second entry: #{string_list[1]}" # => "b"
      #   logger.info "last entry: #{string_list.last}" # => "c"
      #   logger.info "length: #{string_list.size}" # => 3
      #
      class StringListType
        extend Forwardable

        field_reader :typeDetails

        # @!parse include Command, State

        # @!visibility private
        def inspect
          "#<OpenHAB::Core::Types::StringListType #{to_a.inspect}>"
        end

        # @return [Array<String>] the values as an array
        def to_a
          typeDetails.to_a
        end

        # @!visibility private
        def ==(other)
          return super if other.is_a?(StringListType)
          return to_a == other.to_a if other.respond_to?(:to_a)

          super
        end

        # any method that exists on Array gets forwarded to states
        delegate (Array.instance_methods - instance_methods) => :to_a
      end
    end
  end
end

# @!parse StringListType = OpenHAB::Core::Types::StringListType
