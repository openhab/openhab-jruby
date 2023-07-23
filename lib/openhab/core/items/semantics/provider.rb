# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      module Semantics
        #
        # Provides {SemanticTag SemanticTags} created in Ruby to openHAB
        #
        class Provider < Core::Provider
          begin
            include org.openhab.core.semantics.SemanticTagProvider
          rescue NameError
            # @deprecated OH3.4
          end

          class << self
            #
            # The SemanticTag registry
            #
            # @return [org.openhab.core.semantics.SemanticTagRegistry, nil]
            # @since openHAB 4.0
            #
            def registry
              unless instance_variable_defined?(:@registry)
                @registry = OSGi.service("org.openhab.core.semantics.SemanticTagRegistry")
              end
              @registry
            end
          end
        end
      end
    end
  end
end
