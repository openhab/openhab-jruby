# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Actions do
  %i[Exec HTTP Ping].each do |action|
    it "#{action} is available" do
      expect(described_class.constants).to include(action)
    end
  end

  it "Ping#check_vitality works" do
    expect(Ping.check_vitality(nil, 80, 1)).to be false
  end

  describe "#HTTP" do
    it "Stringifies keys in http headers" do
      headers = {
        Cookies: "foo=bar",
        "User-Agent": "JRuby/1.2.3"
      }
      expect(described_class::HTTP).to receive(:sendHttpGetRequest).with(anything,
                                                                         hash_including("Cookies" => "foo=bar",
                                                                                        "User-Agent" => "JRuby/1.2.3"),
                                                                         anything)
      described_class::HTTP.send_http_get_request("http://example.com", headers: headers)
    end
  end

  describe "#notify" do
    it "works" do
      if OpenHAB::Core.version >= OpenHAB::Core::V4_2
        expect(described_class::NotificationAction).to receive(:send_notification)
          .with("email@example.org",
                "Hello, world!",
                nil,
                nil,
                nil,
                nil,
                nil,
                nil,
                nil,
                nil)
      else
        expect(described_class::NotificationAction).to receive(:send_notification)
          .with("email@example.org", "Hello, world!", nil, nil)
      end
      notify("Hello, world!", email: "email@example.org")
    end

    it "can send broadcast notification" do
      if OpenHAB::Core.version >= OpenHAB::Core::V4_2
        expect(described_class::NotificationAction).to receive(:send_broadcast_notification)
          .with("Hello, world!",
                nil,
                nil,
                nil,
                nil,
                nil,
                nil,
                nil,
                nil)
      else
        expect(described_class::NotificationAction).to receive(:send_broadcast_notification)
          .with("Hello, world!", nil, nil)
      end
      notify("Hello, world!")
    end

    # @!deprecated OH 4.1 remove condition/describe guard
    describe "with enhanced parameters", if: OpenHAB::Core.version >= OpenHAB::Core::V4_2 do
      it "accepts buttons as an array" do
        expect(described_class::NotificationAction).to receive(:send_broadcast_notification)
          .with("Hello, world!",
                nil,
                nil,
                nil,
                nil,
                nil,
                "button1",
                "button2",
                "button3")
        notify("Hello, world!", buttons: %w[button1 button2 button3])
      end

      it "accepts buttons as a hash" do
        expect(described_class::NotificationAction).to receive(:send_broadcast_notification)
          .with("Hello, world!",
                nil,
                nil,
                nil,
                nil,
                nil,
                "title1=action1",
                "title2=action2",
                "title 3=action3")
        notify("Hello, world!", buttons: { :title1 => "action1", :title2 => "action2", "title 3" => "action3" })
      end
    end
  end
end
