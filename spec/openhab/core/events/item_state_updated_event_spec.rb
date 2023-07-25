# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::ItemStateUpdatedEvent do
  it "has proper predicates for a NULL event" do
    event = org.openhab.core.items.events.ItemEventFactory.create_state_updated_event("item", NULL)

    expect(event).to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be false
    expect(event.state).to be_nil
  end

  it "has proper predicates for an UNDEF event" do
    event = org.openhab.core.items.events.ItemEventFactory.create_state_updated_event("item", UNDEF)

    expect(event).not_to be_null
    expect(event).to be_undef
    expect(event.state?).to be false
    expect(event.state).to be_nil
  end

  it "has proper predicates for an ON event" do
    event = org.openhab.core.items.events.ItemEventFactory.create_state_updated_event("item", ON)

    expect(event).not_to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be true
    expect(event.state).to be ON
  end
end
