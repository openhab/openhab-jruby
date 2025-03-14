# frozen_string_literal: true

module OpenHAB
  module Core
    # Common base class for array-like collections that have lookup
    # methods to avoid instantiating the elements if you only use
    # the lookup method
    #
    # your class should implement to_a
    #
    module LazyArray
      include Enumerable

      # @!visibility private
      def self.included(klass)
        klass.undef_method :inspect
        klass.undef_method :to_s
      end

      # Calls the given block once for each object, passing that object as a
      # parameter. Returns self.
      #
      # If no block is given, an Enumerator is returned.
      def each(&)
        to_a.each(&)
        self
      end

      # Implicitly convertible to array
      #
      # @return [Array]
      #
      def to_ary
        to_a
      end

      # Delegate any other methods to the actual array, exclude mutating methods
      def method_missing(method, ...)
        return to_a.send(method, ...) if method[-1] != "!" && Array.instance_methods.include?(method)

        super
      end

      # @!visibility private
      def respond_to_missing?(method, include_private = false)
        return true if method[-1] != "!" && Array.instance_methods.include?(method.to_sym)

        super
      end
    end
  end
end
