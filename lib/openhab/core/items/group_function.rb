# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.items.GroupFunction

      #
      # Adds `#to_s` and `#inspect` to group function.
      #
      # @example
      #   # Group:SWITCH:OR(ON,OFF) Switches
      #   logger.info "The Switches group function is: #{Switches.function}" # => "OR"
      #   logger.info "The Switches group function: #{Switches.function.inspect}" # => "OR(ON,OFF)"
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
      end
    end
  end
end
