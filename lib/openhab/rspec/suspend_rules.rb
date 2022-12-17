# frozen_string_literal: true

module OpenHAB
  module RSpec
    # @!visibility private
    module SuspendRules
      # I'd prefer to prepend a module, but I can't because of
      # https://github.com/jruby/jruby/issues/6966#issuecomment-1172983776
      class ::OpenHAB::DSL::Rules::AutomationRule # rubocop:disable Style/ClassAndModuleChildren
        def execute(mod = nil, inputs = nil)
          if SuspendRules.suspended?
            logger.trace("Skipping execution of #{uid} because rules are suspended.")
            return
          end
          execute!(mod, inputs)
        end
      end
      # private_constant :AutomationRule
      # DSL::Rules::AutomationRule.prepend(AutomationRule)

      module DSL
        def after(*, **)
          return if SuspendRules.suspended?

          super
        end
      end
      private_constant :DSL
      OpenHAB::DSL.prepend(DSL)

      @suspended = false

      class << self
        # @!visibility private
        def suspend_rules
          old_suspended = @suspended
          @suspended = true
          yield
        ensure
          @suspended = old_suspended
        end

        # @!visibility private
        def suspended?
          @suspended
        end
      end
    end
  end
end
