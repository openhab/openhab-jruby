# frozen_string_literal: true

require_relative "../config_description/builder"

module OpenHAB
  module DSL
    module Widgets
      # The existing configuration-description DSL with the UI builder's implicit and explicit block styles.
      # Parameters keep their exact names, including underscores, for use through MainUI's `props` object.
      #
      # @see ConfigDescription::Builder#parameter
      #
      class PropertiesBuilder < ConfigDescription::Builder
        include Core::EntityLookup
        include UI::BlockEvaluation

        self.create_dummy_items = true

        # @!visibility private
        def initialize(builder_proxy)
          super()
          @builder_proxy = builder_proxy
        end

        # Declare a property group. Parameters declared in its block automatically belong to this group unless they
        # specify another group name. An `action` context can define implicit action properties without parameters.
        #
        # @param name [String, Symbol] Group name
        # @param label [String, nil] Group label
        # @param description [String, nil] Group description
        # @param advanced [true, false] Whether the group is advanced
        # @param context [String, nil] MainUI property-group context, such as "action"
        # @raise [ArgumentError] If groups are nested
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {PropertiesBuilder PropertiesBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [PropertiesBuilder] The property builder
        # @return [Object, nil] The block result, or nil when no block is given
        def group(name, label: nil, description: nil, advanced: false, context: nil, &)
          raise ArgumentError, "Groups cannot be nested" if @current_group

          super { evaluate(&) }
        end

        # @!visibility private
        def build
          validate_names(@parameters, "property")
          validate_names(@parameter_groups, "property group")
          mapper = org.openhab.core.config.core.dto.ConfigDescriptionDTOMapper
          org.openhab.core.config.core.dto.ConfigDescriptionDTO.new(
            nil,
            mapper.map_parameters(@parameters),
            mapper.map_parameter_groups(@parameter_groups)
          )
        end

        private

        def validate_names(elements, type)
          duplicates = elements.map(&:name).tally.select { |_, count| count > 1 }.keys
          return if duplicates.empty?

          raise ArgumentError, "Duplicate widget #{type} names: #{duplicates.join(", ")}"
        end
      end
    end
  end
end
