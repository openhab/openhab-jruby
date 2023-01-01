# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Java
      # Common extensions to Java Date/Time classes
      module Time
        # @!parse include Comparable

        # @!visibility private
        module ClassMethods
          # The method used to convert another object to this class
          def coercion_method
            @coercion_method ||= :"to_#{java_class.simple_name.gsub(/[A-Z]/, "_\\0").downcase[1..]}"
          end

          # Translate java.time.format.DateTimeParseException to ArgumentError
          def parse(*)
            super
          rescue java.time.format.DateTimeParseException => e
            raise ArgumentError, e.message
          end
        end

        # @!visibility private
        def self.included(klass)
          klass.singleton_class.prepend(ClassMethods)
          klass.remove_method(:==)
          klass.alias_method(:inspect, :to_s)
        end

        #
        # Compare against another time object
        #
        # @param [Object] other The other time object to compare against.
        #
        # @return [Integer] -1, 0, +1 depending on whether `other` is
        #   less than, equal to, or greater than self
        #
        def <=>(other)
          if other.is_a?(self.class)
            compare_to(other)
          elsif other.respond_to?(:coerce)
            return nil unless (lhs, rhs = other.coerce(self))

            lhs <=> rhs
          end
        end

        # Convert `other` to this class, if possible
        # @return [Array, nil]
        def coerce(other)
          coercion_method = self.class.coercion_method
          return unless other.respond_to?(coercion_method)
          return [other.send(coercion_method), self] if other.method(coercion_method).arity.zero?

          [other.send(coercion_method, self), self]
        end
      end
    end
  end
end
