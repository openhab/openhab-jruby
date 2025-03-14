# frozen_string_literal: true

require "singleton"

module OpenHAB
  module Core
    module Rules
      #
      # Provides access to all openHAB {Rule rules}, and acts like an array.
      #
      class Registry
        include LazyArray
        include Singleton

        #
        # Gets a specific Rule
        #
        # @param [String] uid Rule UID
        # @return [Rule, nil]
        #
        def [](uid)
          $rules.get(uid)
        end
        alias_method :include?, :[]
        alias_method :key?, :[]
        # @deprecated
        alias_method :has_key?, :[]

        #
        # Explicit conversion to array
        #
        # @return [Array<Rule>]
        #
        def to_a
          $rules.all.to_a
        end

        #
        # Enter the Rule Builder DSL.
        # @param (see Core::Provider.current)
        # @yield Block executed in the context of a {DSL::Rules::Builder}.
        # @return [Object] The result of the block.
        #
        def build(preferred_provider = nil, &)
          DSL::Rules::Builder.new(preferred_provider).instance_eval_with_dummy_items(&)
        end

        #
        # Remove a Rule.
        #
        # The rule must be a managed thing (typically created by Ruby or in the UI).
        #
        # @param [String, Rule] rule_uid
        # @return [Rule, nil] The removed rule, if found.
        #
        # @example
        #   my_rule = rule do
        #     every :day
        #     run { nil }
        #   end
        #
        #   rules.remove(my_rule)
        #
        def remove(rule_uid)
          rule_uid = rule_uid.uid if rule_uid.is_a?(Rule)
          return nil unless (provider = Provider.registry.provider_for(rule_uid))

          unless provider.is_a?(org.openhab.core.common.registry.ManagedProvider)
            raise "Cannot remove rule #{rule_uid} from non-managed provider #{provider.inspect}"
          end

          provider.remove(rule_uid)
        end

        #
        # Returns all Scenes (rules tagged with "Scene")
        #
        # @return [TaggedArray] A list of all the scenes
        #
        def scenes
          @scenes ||= TaggedArray.new("Scene")
        end

        #
        # Returns all Scripts (rules tagged with "Script")
        #
        # @return [TaggedArray] A list of all the scripts
        #
        def scripts
          @scripts ||= TaggedArray.new("Script")
        end
      end
    end
  end
end
