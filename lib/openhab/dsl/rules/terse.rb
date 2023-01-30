# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      # If you have a single trigger and execution block, you can use a terse rule:
      # All parameters to the trigger are passed through, and an optional `name:` parameter is added.
      #
      # @example
      #   changed TestSwitch do |event|
      #     logger.info("TestSwitch changed to #{event.state}")
      #   end
      #
      # @example
      #   received_command TestSwitch, name: "My Test Switch Rule", command: ON do
      #     logger.info("TestSwitch received command ON")
      #   end
      #
      module Terse
        class << self
          # @!visibility private
          # @!macro def_terse_rule
          #   @!method $1(*args, name :nil, id: nil, on_load: false, **kwargs, &block)
          #   Create a new rule with a $1 trigger.
          #   @param name [String] The name for the rule.
          #   @param id [String] The ID for the rule.
          #   @param on_load [true, false] If the rule should _also_ trigger immediately when the script loads.
          #   @yield The execution block for the rule.
          #   @return [void]
          #   @see BuilderDSL#$1
          def def_terse_rule(trigger)
            class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
              def #{trigger}(*args, name: nil, id: nil, on_load: false, **kwargs, &block)     # def changed(*args, name: nil, id: nil, on_load: false, **kwargs, &block)
                raise ArgumentError, "Block is required" unless block                         #   raise ArgumentError, "Block is required" unless block
                                                                                              #
                id ||= NameInference.infer_rule_id_from_block(block)                          #   id ||= NameInference.infer_rule_id_from_block(block)
                script = block.source rescue nil                                              #   script = block.source rescue nil
                caller_binding = block.binding                                                #   caller_binding = block.binding
                rule name, id: id, script: script, binding: caller_binding do                 #   rule name, id: id, script: script, binding: caller_binding do
                  self.on_load if on_load                                                     #     self.on_load if on_load
                  #{trigger}(*args, **kwargs)                                                 #     changed(*args, **kwargs)
                  run(&block)                                                                 #     run(&block)
                end                                                                           #   end
              end                                                                             # end
              module_function #{trigger.inspect}                                              # module_function :changed
            RUBY
          end
        end

        def_terse_rule(:changed)
        def_terse_rule(:channel)
        def_terse_rule(:channel_linked)
        def_terse_rule(:channel_unlinked)
        def_terse_rule(:cron)
        def_terse_rule(:every)
        def_terse_rule(:item_added)
        def_terse_rule(:item_updated)
        def_terse_rule(:item_removed)
        def_terse_rule(:on_start)
        def_terse_rule(:received_command)
        def_terse_rule(:thing_added)
        def_terse_rule(:thing_updated)
        def_terse_rule(:thing_removed)
        def_terse_rule(:updated)
      end
    end
  end
end
