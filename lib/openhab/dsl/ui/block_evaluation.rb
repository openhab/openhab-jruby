# frozen_string_literal: true

module OpenHAB
  module DSL
    module UI
      # Block evaluation shared by component trees and configuration properties.
      # @!visibility private
      module BlockEvaluation
        # Execute a builder block using the surrounding block style.
        #
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {BlockEvaluator BlockEvaluator}. With an explicit block argument, or when an enclosing block supplies one,
        #   the block retains its surrounding `self`.
        # @yieldparam builder [BlockEvaluator] The component builder
        # @return [Object, nil] The block result, or nil when no block is given
        def evaluate(&block)
          return unless block

          previous_proxy = @builder_proxy
          @builder_proxy ||= SimpleDelegator.new(nil) if block.arity == 1
          if @builder_proxy
            previous = @builder_proxy.__getobj__
            @builder_proxy.__setobj__(self)
            begin
              ThreadLocal.thread_local(openhab_create_dummy_items: true) { yield(@builder_proxy) }
            ensure
              @builder_proxy.__setobj__(previous)
              @builder_proxy = previous_proxy
            end
          else
            instance_eval_with_dummy_items(&block)
          end
        end
      end
    end
  end
end
