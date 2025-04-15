# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      #
      # Provides methods for {https://www.openhab.org/addons/integrations/openhabcloud/#cloud-notification-actions
      # openHAB Cloud Notification Actions}.
      #
      class Notification
        class << self
          #
          # Send a notification using
          # {https://www.openhab.org/addons/integrations/openhabcloud/#cloud-notification-actions
          # openHAB Cloud Notification Action}.
          #
          # @param msg [String] The message to send.
          # @param email [String, nil] The email address to send to. If `nil`, the message will be broadcasted.
          # @param icon [String, Symbol, nil] The icon name
          #   (as described in {https://www.openhab.org/docs/configuration/items.html#icons Items}).
          # @param tag [String, Symbol, nil] a name to group the type or severity of the notification.
          # @param severity [String, Symbol, nil] Deprecated - an alias for `tag` for backwards compatibility.
          # @param title [String, nil] The title of the notification.
          #   When `nil`, it defaults to `openHAB` inside the Android and iOS apps.
          # @param id [String, nil] An optional reference ID which can then be used
          #   to {hide} or update the notification.
          #   Subsequent notifications using the same reference ID will
          #   update/overwrite the existing notification with the same ID.
          # @param on_click [String, nil] The action to be performed when the user clicks on the notification.
          #   Specified using the {https://www.openhab.org/addons/integrations/openhabcloud/#action-syntax
          #   action syntax}.
          # @param attachment [String, Item, nil] The URL of the media attachment to be displayed with the notification.
          #   This can either be a fully qualified URL, prefixed with
          #   `http://` or `https://` and reachable by the client device,
          #   a relative path on the user's openHAB instance starting with `/`,
          #   or an image item.
          # @param buttons [Array<String>, Hash<String, String>, nil] Buttons to include in the notification.
          #   - In array form, each element is specified as `Title=$action`, where `$action` follows the
          #   {https://www.openhab.org/addons/integrations/openhabcloud/#action-syntax action syntax}.
          #   - In hash form, the keys are the button titles and the values are the actions.
          #
          #   The maximum number of buttons is 3.
          # @return [void]
          #
          # @note The parameters `title`, `id`, `on_click`, `attachment`, and `buttons` were added in openHAB 4.2.
          #
          # @see https://www.openhab.org/addons/integrations/openhabcloud/
          #
          # @example Send a broadcast notification via openHAB Cloud
          #   rule "Send an alert" do
          #     changed Alarm_Triggered, to: ON
          #     run { Notification.send "Red Alert!" }
          #   end
          #
          # @example Provide action buttons in a notification
          #   rule "Doorbell" do
          #     changed Doorbell, to: ON
          #     run do
          #       Notification.send "Someone pressed the doorbell!",
          #         title: "Doorbell",
          #         attachment: "http://myserver.local/cameras/frontdoor.jpg",
          #         buttons: {
          #           "Show Camera" => "ui:/basicui/app?w=0001&sitemap=cameras",
          #           "Unlock Door" => "command:FrontDoor_Lock:OFF"
          #         }
          #     end
          #   end
          #
          def send(
            msg,
            email: nil,
            icon: nil,
            tag: nil,
            severity: nil,
            id: nil,
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
            tag ||= severity
            args.push(msg.to_s, icon&.to_s, tag&.to_s)

            # @deprecated OH 4.1
            if Core.version >= Core::V4_2
              buttons ||= []
              buttons = buttons.map { |button_title, action| "#{button_title}=#{action}" } if buttons.is_a?(Hash)
              raise ArgumentError, "buttons must contain (0..3) elements." unless (0..3).cover?(buttons.size)

              attachment = "item:#{attachment.name}" if attachment.is_a?(Item) && attachment.image_item?

              args.push(title&.to_s,
                        id&.to_s,
                        on_click&.to_s,
                        attachment&.to_s,
                        buttons[0]&.to_s,
                        buttons[1]&.to_s,
                        buttons[2]&.to_s)
            end

            NotificationAction.__send__(*args)
          end

          #
          # Hide a notification by ID or tag.
          #
          # Either the `id` or `tag` parameter must be provided.
          # When both are provided, two calls will be made to the NotificationAction:
          # - Notifications matching the `id` will be hidden, and
          # - Notifications matching the `tag` will be hidden, independently from the given tag.
          #
          # @param email [String, nil] The email address to hide notifications for.
          #   If nil, hide broadcast notifications.
          # @param id [String, nil] hide notifications associated with the given reference ID.
          # @param tag [String, nil] hide notifications associated with the given tag.
          # @return [void]
          #
          def hide(email: nil, id: nil, tag: nil)
            unless Actions.const_defined?(:NotificationAction)
              raise NotImplementedError, "NotificationAction is not available. Please install the openHAB Cloud addon."
            end

            raise ArgumentError, "Either id or tag must be provided." unless id || tag

            args = []
            if email
              args.push(email)
              notification = :notification
            else
              notification = :broadcast_notification
            end

            NotificationAction.__send__(:"hide_#{notification}_by_reference_id", *args, id) if id
            NotificationAction.__send__(:"hide_#{notification}_by_tag", *args, tag) if tag
          end

          #
          # Sends a log notification.
          #
          # Log notifications do not trigger a notification on the device.
          #
          # @param msg [String] The message to send.
          # @param icon [String, Symbol, nil] The icon name
          # @param tag [String, Symbol, nil] a name to group the type or severity of the notification.
          # @return [void]
          #
          def log(msg, icon: nil, tag: nil)
            NotificationAction.send_log_notification(msg.to_s, icon&.to_s, tag&.to_s)
          end
        end

        Object.const_set(name.split("::").last, self)
      end
    end
  end
end
