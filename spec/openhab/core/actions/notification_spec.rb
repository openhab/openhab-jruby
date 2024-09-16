# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Actions::Notification do
  describe "#send" do
    describe "when sending to a user" do
      it "works with minimal arguments" do
        if OpenHAB::Core.version >= OpenHAB::Core::V4_2
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_notification)
            .with("email@example.org", "Hello, world!", nil, nil, nil, nil, nil, nil, nil, nil, nil)
        else
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_notification)
            .with("email@example.org", "Hello, world!", nil, nil)
        end
        Notification.send("Hello, world!", email: "email@example.org")
      end

      it "works with full arguments" do
        if OpenHAB::Core.version >= OpenHAB::Core::V4_2
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_notification)
            .with("email@example.org", "Hello, world!", "icon", "tag", nil, nil, nil, nil, nil, nil, nil)
        else
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_notification)
            .with("email@example.org", "Hello, world!", "icon", "tag")
        end
        Notification.send("Hello, world!", email: "email@example.org", icon: "icon", tag: "tag")
      end
    end

    describe "when broadcasting" do
      it "works with minimal arguments" do
        if OpenHAB::Core.version >= OpenHAB::Core::V4_2
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
            .with("Hello, world!", nil, nil, nil, nil, nil, nil, nil, nil, nil)
        else
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
            .with("Hello, world!", nil, nil)
        end
        Notification.send("Hello, world!")
      end

      it "works with full arguments" do
        if OpenHAB::Core.version >= OpenHAB::Core::V4_2
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
            .with("Hello, world!", "icon", "tag", nil, nil, nil, nil, nil, nil, nil)
        else
          expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
            .with("Hello, world!", "icon", "tag")
        end
        Notification.send("Hello, world!", icon: "icon", tag: "tag")
      end
    end

    # @deprecated OH 4.1 remove condition/describe guard
    describe "with enhanced parameters", if: OpenHAB::Core.version >= OpenHAB::Core::V4_2 do
      it "works" do
        expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
          .with("msg",
                "icon",
                "tag",
                "title",
                "id",
                "on_click",
                "attachment",
                "button1",
                "button2",
                "button3")
        Notification.send("msg", # rubocop:disable Performance/StringIdentifierArgument
                          icon: "icon",
                          tag: "tag",
                          title: "title",
                          id: "id",
                          on_click: "on_click",
                          attachment: "attachment",
                          buttons: %w[button1 button2 button3])
      end

      it "accepts buttons as a hash" do
        expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
          .with("Hello, world!",
                nil,
                nil,
                nil,
                nil,
                nil,
                nil,
                "title1=action1",
                "title2=action2",
                "title 3=action3")
        Notification.send("Hello, world!",
                          buttons: { :title1 => "action1", :title2 => "action2", "title 3" => "action3" })
      end

      it "accepts an Image item as an attachment" do
        items.build { image_item MyImageItem }
        expect(OpenHAB::Core::Actions::NotificationAction).to receive(:send_broadcast_notification)
          .with("Hello, world!",
                nil,
                nil,
                nil,
                nil,
                nil,
                "item:MyImageItem",
                nil,
                nil,
                nil)
        Notification.send("Hello, world!", attachment: MyImageItem)
      end
    end
  end

  describe "#hide" do
    it "hides notification by reference ID" do
      expect(OpenHAB::Core::Actions::NotificationAction).to receive(:hide_notification_by_reference_id)
        .with("email@example.org", "id")
      Notification.hide(email: "email@example.org", id: "id")
    end

    it "hides notifications by tag" do
      expect(OpenHAB::Core::Actions::NotificationAction).to receive(:hide_notification_by_tag)
        .with("email@example.org", "tag")
      Notification.hide(email: "email@example.org", tag: "tag")
    end

    it "hides broadcast notification by reference ID" do
      expect(OpenHAB::Core::Actions::NotificationAction).to receive(:hide_broadcast_notification_by_reference_id)
        .with("id")
      Notification.hide(id: "id")
    end

    it "hides broadcast notifications by tag" do
      expect(OpenHAB::Core::Actions::NotificationAction).to receive(:hide_broadcast_notification_by_tag)
        .with("tag")
      Notification.hide(tag: "tag")
    end
  end
end
