# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::ItemStateUpdatedEvent do
  it "is inspectable" do
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", NULL, nil)
    expect(event.inspect).to eql "#<OpenHAB::Core::Events::ItemStateUpdatedEvent item=item state=NULL>"

    # @deprecated OH4.3 remove args and pass 4 arguments directly when dropping oh 4.3
    args = ["item", NULL]
    args << nil if OpenHAB::Core.full_version > Gem::Version.new("5.0.0.M1")
    args << "source"
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event(*args)
    expect(event.inspect).to eql(
      '#<OpenHAB::Core::Events::ItemStateUpdatedEvent item=item state=NULL source="source">'
    )
  end

  it "has proper predicates for a NULL event" do
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", NULL, nil)

    expect(event).to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be false
    expect(event.state).to be_nil
  end

  it "has proper predicates for an UNDEF event" do
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", UNDEF, nil)

    expect(event).not_to be_null
    expect(event).to be_undef
    expect(event.state?).to be false
    expect(event.state).to be_nil
  end

  it "has proper predicates for an ON event" do
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", ON, nil)

    expect(event).not_to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be true
    expect(event.state).to be ON
  end
end
