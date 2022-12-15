# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      #
      # Provides methods to support DSL properties
      #
      # @visibility private
      module Property
        #
        # Dynamically creates a property that acts as an accessor with no arguments
        # and a setter with any number of arguments or a block.
        #
        # @param [String] name of the property
        #
        def prop(name)
          # rubocop rules are disabled because this method is dynamically defined on the calling
          #   object making calls to other methods in this module impossible, or if done on methods
          #   in this module than instance variable belong to the module not the calling class
          define_method(name) do |*args, &block|
            if args.length.zero? && block.nil? == true
              instance_variable_get("@#{name}")
            else
              logger.trace("Property '#{name}' called with args(#{args}) and block(#{block})")
              if args.length == 1
                instance_variable_set("@#{name}", args.first)
              elsif args.length > 1
                instance_variable_set("@#{name}", args)
              elsif block
                instance_variable_set("@#{name}", block)
              end
            end
          end
        end

        #
        # Dynamically creates a property array that acts as an accessor with no arguments
        # and pushes any number of arguments or a block onto the property array
        # You can provide a block to this method which can be used to check if the provided value is acceptable.
        #
        # @param [String] name of the property
        # @param [String] array_name name of the array to use, defaults to name of property
        # @param [Class] wrapper object to put around elements added to the array
        #
        def prop_array(name, array_name: nil, wrapper: nil)
          define_method(name) do |*args, &block|
            array_name ||= name
            if args.length.zero? && block.nil? == true
              instance_variable_get("@#{array_name}")
            else
              logger.trace("Property '#{name}' called with args(#{args}) and block(#{block})")
              if args.length == 1
                insert = args.first
              elsif args.length > 1
                insert = args
              elsif block
                insert = block
              end
              yield insert if block_given?
              insert = wrapper.new(insert) if wrapper
              instance_variable_set("@#{array_name}", (instance_variable_get("@#{array_name}") || []) << insert)
            end
          end

          return unless array_name

          define_method(array_name) do
            instance_variable_get("@#{array_name}")
          end
        end
      end
    end
  end
end
