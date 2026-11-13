# frozen_string_literal: true

require "forwardable"

require "securerandom"

require_relative "triggers/conditions/generic"

module OpenHAB
  module DSL
    module Rules
      #
      # Rule configuration for openHAB Rules engine
      #
      # @!visibility private
      class RuleTriggers
        # @return [Array] Of triggers
        attr_accessor :triggers

        # @return [Hash] Of trigger conditions
        attr_reader :trigger_conditions

        # @return [Hash] Hash of trigger UIDs to attachments
        attr_reader :attachments

        #
        # Create a new RuleTrigger
        #
        def initialize
          @triggers = []
          @trigger_conditions = Hash.new(Triggers::Conditions::Generic::ANY)
          @attachments = {}
        end

        #
        # Append a trigger to the list of triggers
        #
        # @param [String] type of trigger to create
        # @param [Map] config map describing trigger configuration
        # @param [Object] attach object to be attached to the trigger
        #
        # @return [org.openhab.core.automation.Trigger] openHAB trigger
        #
        def append_trigger(type:, config:, attach: nil, conditions: nil, label: nil)
          config.transform_keys!(&:to_s)
          RuleTriggers.trigger(type:, config:, label:).tap do |trigger|
            logger.trace { "Appending trigger (#{trigger.inspect}) attach (#{attach}) conditions(#{conditions})" }
            @triggers << trigger
            @attachments[trigger.id] = attach if attach
            @trigger_conditions[trigger.id] = conditions if conditions
          end
        end

        #
        # Create a trigger
        #
        # @param [String] type of trigger
        # @param [Map] config map
        # @param [String] label for the trigger
        # @param [String] id for the trigger
        #
        # @return [org.openhab.core.automation.Trigger] configured by type and supplied config
        #
        def self.trigger(type:, config:, label: nil, id: nil)
          id ||= SecureRandom.uuid
          logger.trace { "Creating trigger of type '#{type}' config: #{config}" }
          org.openhab.core.automation.util.TriggerBuilder.create
             .with_id(id)
             .with_type_uid(type)
             .with_configuration(Core::Configuration.new(config))
             .with_label(label)
             .build
        end

        #
        # Inspect the config object
        #
        # @return [String] details of the config object
        #
        def inspect
          <<~TEXT.tr("\n", " ")
            #<RuleTriggers #{triggers.inspect}
            Conditions: #{trigger_conditions.inspect}
            UIDs: #{triggers.map(&:id).inspect}
            Attachments: #{attachments.inspect}>
          TEXT
        end

        # Assign module IDs once the rule UID is final, preserving attachment and condition mappings.
        # @param [String] rule_uid The finalized rule UID
        # @return [void]
        def finalize_ids(rule_uid)
          return unless rule_uid

          prefix = rule_uid.gsub(/[^A-Za-z0-9_-]/, "_")
          @triggers = triggers.each_with_index.map do |trigger, index|
            id = "#{prefix}-#{index + 1}"
            attachments[id] = attachments.delete(trigger.id) if attachments.key?(trigger.id)
            trigger_conditions[id] = trigger_conditions.delete(trigger.id) if trigger_conditions.key?(trigger.id)
            org.openhab.core.automation.util.TriggerBuilder.create(trigger).with_id(id).build
          end
        end
      end
    end
  end
end
