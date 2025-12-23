# frozen_string_literal: true

RSpec.describe "persistence" do
  it "works" do
    items.build { switch_item "MySwitch" }
    MySwitch.on
    MySwitch.persist
    MySwitch.off
    MySwitch.persist
    expect(MySwitch.previous_state(skip_equal: false)).to eq OFF
    expect(MySwitch.previous_state(skip_equal: true)).to eq ON
  end
end
