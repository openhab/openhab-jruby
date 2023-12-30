# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.type.ChannelType

      #
      # {ChannelGroupType} contains a list of
      # {ChannelDefinition channel definitions} and further meta information
      # such as label and description, which are generally used by user
      # interfaces.
      #
      # @!attribute [r] uid
      #   @return [ChannelTypeUID]
      #
      # @!attribute [r] item_type
      #   @return [String]
      #
      # @!attribute [r] tags
      #   @return [Set<String>]
      #
      # @!attribute [r] category
      #   @return [String, nil]
      #
      class ChannelType < AbstractDescriptionType
        class << self
          # @!visibility private
          def registry
            @registry ||= OSGi.service("org.openhab.core.thing.type.ChannelTypeRegistry")
          end
        end

        # @!attribute [r] kind
        # @return [:state, :trigger]
        def kind
          get_kind.to_s.to_sym
        end

        # @!attribute [r] advanced?
        # @return [true, false]
        alias_method :advanced?, :advanced

        # @!visibility private
        alias_method :state_description, :state

        # @!attribute [r] auto_update_policy
        # @return [:veto, :default, :recommend, nil]
        def auto_update_policy
          get_auto_update_policy&.to_s&.downcase&.to_sym
        end

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::ChannelType #{uid}"
          r += " (#{kind})" unless kind == :state
          r += " (advanced)" if advanced?
          r += " item_type=#{item_type}"
          r += " tags=(#{tags.join(", ")})" unless tags.empty?
          r += " category=#{category.inspect}" if category
          r += " auto_update_policy=#{auto_update_policy}" if auto_update_policy
          "#{r}>"
        end

        # @return [String]
        def to_s
          uid.to_s
        end
      end
    end
  end
end
