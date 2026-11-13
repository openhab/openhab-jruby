# frozen_string_literal: true

module OpenHAB
  module Core
    # Infrastructure shared by MainUI pages and reusable widgets.
    module UI
      # Provides script-owned UI components in a namespace.
      # @abstract Subclasses supply {.namespace}.
      class Provider < Core::Provider
        include org.openhab.core.ui.components.UIComponentProvider

        class << self
          # @return [org.openhab.core.ui.components.UIComponentRegistry]
          def registry
            factory = OSGi.service("org.openhab.core.ui.components.UIComponentRegistryFactory")
            raise "MainUI component registry is unavailable" unless factory

            factory.get_registry(namespace)
          end
        end

        # @!visibility private
        def getNamespace # rubocop:disable Naming/MethodName
          self.class.namespace
        end
      end
    end
  end
end
