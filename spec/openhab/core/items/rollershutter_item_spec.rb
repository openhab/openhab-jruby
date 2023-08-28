# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::RollershutterItem do
  subject(:item) { RollerOne }

  before do
    items.build do
      group_item "Rollershutters" do
        rollershutter_item "RollerOne", state: 50
        rollershutter_item "RollerTwo", state: 70
      end
    end
  end

  it "is a rollershutter" do
    expect(item).to be_a_rollershutter_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  describe "#command" do
    specify { expect((item << 70).state).to eq 70 }
    specify { expect((item << PercentType.new(10)).state).to eq 10 }
  end

  describe "command methods" do
    specify { expect(item.up.state).to eq 0 }
    specify { expect(item.down.state).to eq 100 }

    %i[stop move].each do |method|
      it "sends #{method} command as a method" do
        received = nil
        received_command item do |event|
          received = event.command
        end

        item.send(method)
        expect(received.to_s).to eql method.to_s.upcase
      end
    end
  end

  describe "state predicates" do
    specify { expect(item).not_to be_up }
    specify { expect(item).not_to be_down }
    specify { expect(item.update(0)).to be_up }
    specify { expect(item.update(0)).not_to be_down }
    specify { expect(item.update(100)).not_to be_up }
    specify { expect(item.update(100)).to be_down }
  end
end
