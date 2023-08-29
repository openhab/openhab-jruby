# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.items.GroupFunction

      #
      # Adds predicates to check the type of group function.
      #
      # @example
      #   # Group:SWITCH:OR(ON,OFF) Switches
      #   # Switch Switch1 (Switches)
      #   logger.info "The Switches group function is: #{Switches.function}" # => "OR"
      #   logger.info "The Switches group function: #{Switches.function.inspect}" # => "OR(ON,OFF)"
      #   logger.info "The Switches group function is an OR? #{Switches.function.or?}" # => true
      #
      module GroupFunction
        #
        # Returns the group function as an uppercase string
        # @return [String]
        #
        def to_s
          self.class.simple_name.upcase
        end

        #
        # Returns the group function and its parameters as a string
        # @return [String]
        #
        def inspect
          params = parameters.map(&:inspect).join(",")
          params = "(#{params})" unless params.empty?
          "#{self}#{params}"
        end

        # @!method equality?
        #   Checks if group function is `EQUALITY`
        #   @return [true, false]

        # @!method count?
        #   Checks if group function is `COUNT`
        #   @return [true, false]

        # @!method min?
        #   Checks if group function is `MIN`
        #   @return [true, false]

        # @!method max?
        #   Checks if group function is `MAX`
        #   @return [true, false]

        # @!method sum?
        #   Checks if group function is `SUM`
        #   @return [true, false]

        # @!method avg?
        #   Checks if group function is `AVG`
        #   @return [true, false]

        # @!method and?
        #   Checks if group function is `AND`
        #   @return [true, false]

        # @!method or?
        #   Checks if group function is `OR`
        #   @return [true, false]

        # @!method nor?
        #   Checks if group function is `NOR`
        #   @return [true, false]

        # @!method nand?
        #   Checks if group function is `NAND`
        #   @return [true, false]

        # @!method earliest?
        #   Checks if group function is `EARLIEST`
        #   @return [true, false]

        # @!method latest?
        #   Checks if group function is `LATEST`
        #   @return [true, false]

        FUNCTIONS = [org.openhab.core.items.GroupFunction,
                     org.openhab.core.library.types.ArithmeticGroupFunction,
                     org.openhab.core.library.types.DateTimeGroupFunction]
                    .map { |parent_group| parent_group.java_class.declared_classes.to_a }
                    .flatten
                    .map { |klass| "#{klass.simple_name.downcase}?".to_sym }
                    .freeze
        private_constant :FUNCTIONS

        # Implements the group function type predicates
        def method_missing(name, *args, &block)
          return super unless FUNCTIONS.include?(name)

          to_s.casecmp?(name.to_s.delete_suffix!("?"))
        end

        # @!visibility private
        def respond_to_missing?(name, include_private = false)
          FUNCTIONS.include?(name) || super
        end
      end
    end
  end
end
