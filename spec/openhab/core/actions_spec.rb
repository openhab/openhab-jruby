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
      described_class::HTTP.send_http_get_request("http://example.com", headers:)
    end
  end
end
