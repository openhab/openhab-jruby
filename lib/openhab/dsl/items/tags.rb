# frozen_string_literal: true

module OpenHAB
  module DSL
    module Items
      # A helper module for handling tags in OpenHAB DSL.
      module Tags
        module_function

        #
        # Convert the given array to an array of strings.
        # Convert Semantics classes to their simple name.
        #
        # @param [String,Symbol,Semantics::Tag] tags A list of strings, symbols, or Semantics classes
        # @return [Array] An array of strings
        #
        # @example
        #   tags = normalize("tag1", Semantics::LivingRoom)
        #
        # @!visibility private
        def normalize(*tags)
          tags.compact.map do |tag|
            case tag
            when String then tag
            when Symbol, Semantics::SemanticTag then tag.to_s
            else raise ArgumentError,
                       "`#{tag}` must be a subclass of Semantics::Tag, a `Symbol`, or a `String`."
            end
          end
        end
      end
    end
  end
end
