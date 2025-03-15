# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::TimerEvent do
  describe "#cron_expression" do
    it "works" do
      expression = (Time.now + 2).strftime("%S %M %H ? * ?")
      event = described_class.new("topic", %({"cronExpression":"#{expression}"}), nil)
      expect(event.cron_expression).to eql expression
    end
  end

  describe "#item" do
    it "works" do
      items.build { date_time_item MyDateTimeItem }
      event = described_class.new("topic", %({"itemName":"MyDateTimeItem"}), nil)
      expect(event.item).to be_an(Item)
      expect(event.item).to eql MyDateTimeItem
    end
  end

  describe "#time" do
    it "works" do
      event = described_class.new("topic", %({"time":"12:34"}), nil)
      expect(event.time).to be_a(java.time.LocalTime)
      expect(event.time).to eq LocalTime.parse("12:34")
    end
  end
end
