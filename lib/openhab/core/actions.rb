# frozen_string_literal: true

module OpenHAB
  module Core
    #
    # Access to global actions.
    #
    # All openHAB's actions including those provided by add-ons are available, notably:
    # * {Audio}
    # * {CoreExt::Ephemeris Ephemeris}
    # * {Exec}
    # * {HTTP}
    # * {Items::Persistence PersistenceExtensions}
    # * {Ping}
    # * {Items::Semantics Semantics}
    # * {Transformation}
    # * {Voice}
    #
    # From add-ons, e.g.:
    # * {Notification NotificationAction} from
    #   [openHAB Cloud Connector](https://www.openhab.org/addons/integrations/openhabcloud/)
    #
    # Thing-specific actions can be accessed from the {Things::Thing Thing} object.
    # See {Things::Thing#actions Thing#actions}.
    #
    module Actions
      OSGi.services("org.openhab.core.model.script.engine.action.ActionService")&.each do |service|
        action_class = service.action_class
        module_name = action_class.simple_name
        action = if action_class.interface?
                   impl = OSGi.service(action_class)
                   unless impl
                     logger.error("Unable to find an implementation object for action service #{action_class}.")
                     next
                   end
                   const_set(module_name, impl)
                 else
                   (java_import action_class.ruby_class).first
                 end
        logger.trace { "Loaded ACTION: #{action_class}" }
        Object.const_set(module_name, action)
      end

      # Import common actions
      %w[Exec HTTP Ping Transformation].each do |action|
        klass = (java_import "org.openhab.core.model.script.actions.#{action}").first
        Object.const_set(action, klass)
      end

      module_function

      #
      # @!method notify(msg, email: nil, icon: nil, tag: nil, severity: nil, id: nil, title: nil, on_click: nil, attachment: nil, buttons: nil)
      # @deprecated Use {Notification.send Notification.send} instead.
      #
      def notify(*args, **kwargs)
        logger.warn("`notify` method is deprecated. Use `Notification.send` instead.")
        Notification.send(*args, **kwargs)
      end
    end
  end
end
