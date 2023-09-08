# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::PlayerItem do
  subject(:item) { items.build { player_item "PlayerOne" } }

  it "is a player" do
    expect(item).to be_a_player_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  describe "sending commands" do
    specify { expect((item << PLAY).state).to be PLAY }
    specify { expect((item << PAUSE).state).to be PAUSE }
    specify { expect((item << REWIND).state).to be REWIND }
    specify { expect((item << FASTFORWARD).state).to be FASTFORWARD }

    %i[NEXT PREVIOUS].each do |command|
      it "sends #{command} command" do
        received = nil
        received_command item do |event|
          received = event.command
        end

        command = Object.const_get(command)
        item << command
        expect(received).to be command
      end
    end
    %i[next previous].each do |method|
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

  describe "command methods" do
    specify { expect(item.play.state).to be PLAY }
    specify { expect(item.pause.state).to be PAUSE }
    specify { expect(item.rewind.state).to be REWIND }
    specify { expect(item.fast_forward.state).to be FASTFORWARD }
  end

  describe "state methods" do
    specify { expect(item.update(PLAY)).to be_playing }
    specify { expect(item.update(PAUSE)).to be_paused }
    specify { expect(item.update(REWIND)).to be_rewinding }
    specify { expect(item.update(FASTFORWARD)).to be_fast_forwarding }
  end
end
