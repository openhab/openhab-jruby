# frozen_string_literal: true

module OpenHAB
  module DSL
    #
    # Contains the DSL for creating {org.openhab.core.config.core.ConfigDescription} instances.
    #
    module ConfigDescription
      #
      # A ConfigDescriptionBuilder is used to create a {org.openhab.core.config.core.ConfigDescription}
      # instance.
      #
      # @see DSL.config_description config_description
      #
      class Builder
        def initialize
          @parameters = []
          @parameter_groups = []
          @current_group = nil
        end

        #
        # Create a parameter group.
        #
        # @param [String, Symbol] name The group name. This name will be referred to by {parameter}.
        # @param [String, nil] label The group label
        # @param [String, nil] description The group description
        # @param [Boolean] advanced Whether the group is advanced
        # @param [<Type>] context Context for the group
        #
        # @yield Block executed in the context of this group. Any {parameter} calls within the block will
        #   automatically be added to this group, unless it specifies a different group name.
        #
        # @return [void]
        #
        def group(name, label: nil, description: nil, advanced: false, context: nil, &block)
          raise ArgumentError, "Groups cannot be nested" if @current_group

          name = name.to_s
          @parameter_groups << org.openhab.core.config.core.ConfigDescriptionParameterGroupBuilder
                                  .create(name)
                                  .with_label(label)
                                  .with_description(description)
                                  .with_advanced(advanced)
                                  .with_context(context)
                                  .build

          @current_group = name
          instance_eval(&block) if block
        ensure
          @current_group = nil
        end

        #
        # Adds a parameter to the config description.
        #
        # @param [String, Symbol] name Parameter name
        # @param [:text, :integer, :decimal, :boolean] type
        #   Parameter type. See {org.openhab.core.config.core.ConfigDescriptionParameter.Type}
        # @param [String, nil] label Parameter label
        # @param [String, nil] description Parameter description
        # @param [Numeric, nil] min Minimum value for numeric types
        # @param [Numeric, nil] max Maximum value for numeric types
        # @param [Numeric, nil] step Step size for numeric types
        # @param [String, nil] pattern Regular expression pattern for string types
        # @param [true, false] required Whether the parameter is required
        # @param [true, false] read_only Whether the parameter is read only
        # @param [true, false] multiple Whether the parameter is a list of values
        # @param [String, nil] context Context for the parameter
        # @param [Object, nil] default Default value for the parameter
        # @param [Hash] options Options for the parameter
        # @param [Hash] filter_criteria Filter criteria for the parameter
        # @param [String, nil] group_name Parameter group name.
        #   When nil, it will be inferred when this method is called inside a {group} block.
        # @param [true, false] advanced Whether the parameter is advanced
        # @param [true, false] limit_to_options Whether the parameter is limited to the given options
        # @param [Integer, nil] multiple_limit Maximum number of values for a multiple parameter
        # @param [String, nil] unit Parameter unit
        # @param [String, nil] unit_label Parameter unit label
        # @param [true, false] verify Whether the parameter value should be verified
        #
        # @return [void]
        #
        # @see org.openhab.core.config.core.ConfigDescriptionParameter
        #
        def parameter(name,
                      type,
                      label: nil,
                      description: nil,
                      min: nil,
                      max: nil,
                      step: nil,
                      pattern: nil,
                      required: false,
                      read_only: false,
                      multiple: false,
                      context: nil,
                      default: nil,
                      options: {},
                      filter_criteria: {},
                      group_name: nil,
                      advanced: false,
                      limit_to_options: false,
                      multiple_limit: nil,
                      unit: nil,
                      unit_label: nil,
                      verify: false)
          # Extract the named arguments into a hash
          @parameters << method(__method__).parameters
                                           .select { |param_type, _| param_type == :key } # rubocop:disable Style/HashSlice
                                           .to_h { |_, key| [key, binding.local_variable_get(key)] }
                                           .then do |p|
            p[:options] = p[:options].map do |opt_value, opt_label|
              org.openhab.core.config.core.ParameterOption.new(opt_value, opt_label)
            end
            p[:filter_criteria] = p[:filter_criteria].map do |filter_name, filter_value|
              org.openhab.core.config.core.FilterCriteria.new(filter_name, filter_value)
            end
            p[:minimum] = p.delete(:min)&.to_d&.to_java
            p[:maximum] = p.delete(:max)&.to_d&.to_java
            p[:step] = p.delete(:step)&.to_d&.to_java
            p[:group_name] ||= @current_group
            type = org.openhab.core.config.core.ConfigDescriptionParameter::Type.value_of(type.to_s.upcase)

            parameter = org.openhab.core.config.core.ConfigDescriptionParameterBuilder.create(name.to_s, type)

            p.each do |key, value|
              parameter.send(:"with_#{key}", value) unless value.nil?
            end
            parameter.build
          end
        end

        #
        # Build the config description
        #
        # @param [String, java.net.URI] uri The URI for the config description. When nil, it will default to `dummy:uri`
        # @yield Block executed in the context of this builder. Inside the block, you can call {parameter} and {group}.
        #
        # @return [org.openhab.core.config.core.ConfigDescription] The created ConfigDescription object
        #
        def build(uri = nil, &block)
          instance_eval(&block) if block
          raise ArgumentError, "No parameters defined" if @parameters.empty?

          uri ||= "dummy:uri"
          uri = java.net.URI.new(uri.to_s) unless uri.is_a?(java.net.URI)
          org.openhab.core.config.core.ConfigDescriptionBuilder
             .create(uri)
             .with_parameters(@parameters)
             .with_parameter_groups(@parameter_groups)
             .build
        end
      end
    end
  end
end
