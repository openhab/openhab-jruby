# frozen_string_literal: true

require "method_source"

module OpenHAB
  module CoreExt
    #
    # Patches to gems
    #
    module Gems
      #
      # Patches to the method_source gem
      #
      module MethodSourceScriptPatch
        #
        # Read source lines from openHAB UI scripts when target file is "<script>".
        #
        def lines_for(file_name, line = nil)
          if file_name == "<script>" && (uid = $ctx&.[]("ruleUID"))
            script = OpenHAB::DSL.rules[uid]&.actions&.first&.configuration&.[]("script")
            return script.lines if script
          end

          super
        end
      end
    end
  end
end

MethodSource.singleton_class.prepend(OpenHAB::CoreExt::Gems::MethodSourceScriptPatch)
