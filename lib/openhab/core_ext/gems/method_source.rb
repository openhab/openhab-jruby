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
            action = OpenHAB::DSL.rules[uid]&.actions&.find do |candidate|
              next unless candidate.type_uid == "script.ScriptAction"

              # The script identifier is the owning handler's engine UUID, not its action ID.
              factory = OpenHAB::Core::Rules.manager.get_module_handler_factory(candidate.type_uid)
              handler = factory&.get_handler(candidate, uid)
              handler&.engine_identifier == $scriptExtension.script_identifier
            end
            script = action&.configuration&.[]("script")
            return script.lines if script
          end

          super
        end
      end
    end
  end
end

MethodSource.singleton_class.prepend(OpenHAB::CoreExt::Gems::MethodSourceScriptPatch)
