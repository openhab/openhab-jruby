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
    # * NotificationAction (from
    #   [openHAB Cloud Connector](https://www.openhab.org/addons/integrations/openhabcloud/);
    #   see {notify notify})
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
        logger.trace("Loaded ACTION: #{action_class}")
        Object.const_set(module_name, action)
      end

      # Import common actions
      %w[Exec HTTP Ping Transformation].each do |action|
        klass = (java_import "org.openhab.core.model.script.actions.#{action}").first
        Object.const_set(action, klass)
      end

      module_function

      #
      # Send a notification using
      # {https://next.openhab.org/addons/integrations/openhabcloud/#cloud-notification-actions
      # openHAB Cloud Notification Action}.
      #
      # @param msg [String] The message to send.
      # @param email [String, nil] The email address to send to. If `nil`, the message will be broadcast.
      # @param icon [String, Symbol, nil] The icon name
      #   (as described in {https://next.openhab.org/docs/configuration/items.html#icons Items}).
      # @param severity [String, Symbol, nil] A description of the severity of the incident.
      # @param title [String, nil] The title of the notification.
      #   When `nil`, it defaults to `openHAB` inside the Android and iOS apps.
      # @param on_click [String, nil] The action to be performed when the user clicks on the notification.
      #   Specified using the {https://next.openhab.org/addons/integrations/openhabcloud/#action-syntax action syntax}.
      # @param attachment [String, nil] The URL of the media attachment to be displayed with the notification.
      #   This URL must be reachable by the push notification client.
      # @param buttons [Array<String>, Hash<String, String>, nil] Buttons to include in the notification.
      #   - In array form, each element is specified as `Title=$action`, where `$action` follows the
      #   {https://next.openhab.org/addons/integrations/openhabcloud/#action-syntax action syntax}.
      #   - In hash form, the keys are the button titles and the values are the actions.
      #
      #   The maximum number of buttons is 3.
      # @return [void]
      #
      # @note The parameters `title`, `on_click`, `attachment`, and `buttons` were added in openHAB 4.2.
      #
      # @see https://www.openhab.org/addons/integrations/openhabcloud/
      #
      # @example Send a broadcast notification via openHAB Cloud
      #   rule "Send an alert" do
      #     changed Alarm_Triggered, to: ON
      #     run { notify "Red Alert!" }
      #   end
      #
      # @example Provide action buttons in a notification
      #   rule "Doorbell" do
      #     changed Doorbell, to: ON
      #     run do
      #       notify "Someone pressed the doorbell!",
      #         title: "Doorbell",
      #         attachment: "http://myserver.local/cameras/frontdoor.jpg",
      #         buttons: {
      #           "Show Camera" => "ui:/basicui/app?w=0001&sitemap=cameras",
      #           "Unlock Door" => "command:FrontDoor_Lock:OFF"
      #         }
      #     end
      #   end
      #
      def notify(
        msg,
        email: nil,
        icon: nil,
        severity: nil,
        title: nil,
        on_click: nil,
        attachment: nil,
        buttons: nil
      )
        unless Actions.const_defined?(:NotificationAction)
          raise NotImplementedError, "NotificationAction is not available. Please install the openHAB Cloud addon."
        end

        args = []
        if email
          args.push(:send_notification, email)
        else
          args.push(:send_broadcast_notification)
        end
        args.push(msg.to_s, icon&.to_s, severity&.to_s)

        # @!deprecated OH 4.1
        if Core.version >= Core::V4_2
          buttons ||= []
          buttons = buttons.map { |title, action| "#{title}=#{action}" } if buttons.is_a?(Hash)
          raise ArgumentError, "buttons must contain (0..3) elements." unless (0..3).cover?(buttons.size)

          args.push(title&.to_s, on_click&.to_s, attachment&.to_s, buttons[0]&.to_s, buttons[1]&.to_s, buttons[2]&.to_s)
        end

        NotificationAction.__send__(*args)
      end
    end
  end
end
