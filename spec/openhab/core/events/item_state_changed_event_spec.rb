# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::ItemStateChangedEvent do
  it "is inspectable" do
    # @deprecated OH4.3 remove args and pass 5 arguments directly when dropping oh 4.3
    args = ["item", NULL, ON]
    args += [nil, nil] if OpenHAB::Core.full_version > Gem::Version.new("5.0.0.M1")
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_changed_event(*args)
    expect(event.inspect).to eql "#<OpenHAB::Core::Events::ItemStateChangedEvent item=item state=NULL was=ON>"
  end

  it "has proper predicates for an ON => NULL event" do
    # @deprecated OH4.3 remove args and pass 5 arguments directly when dropping oh 4.3
    args = ["item", NULL, ON]
    args += [nil, nil] if OpenHAB::Core.full_version > Gem::Version.new("5.0.0.M1")
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_changed_event(*args)

    expect(event).to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be false
    expect(event.state).to be_nil
    expect(event.was_null?).to be false
    expect(event.was_undef?).to be false
    expect(event.was?).to be true
    expect(event.was).to be ON
  end

  it "has proper predicates for an ON => UNDEF event" do
    # @deprecated OH4.3 remove args and pass 5 arguments directly when dropping oh 4.3
    args = ["item", UNDEF, ON]
    args += [nil, nil] if OpenHAB::Core.full_version > Gem::Version.new("5.0.0.M1")
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_changed_event(*args)

    expect(event).not_to be_null
    expect(event).to be_undef
    expect(event.state?).to be false
    expect(event.state).to be_nil
    expect(event.was_null?).to be false
    expect(event.was_undef?).to be false
    expect(event.was?).to be true
    expect(event.was).to be ON
  end

  it "has proper predicates for a NULL => ON event" do
    # @deprecated OH4.3 remove args and pass 5 arguments directly when dropping oh 4.3
    args = ["item", ON, NULL]
    args += [nil, nil] if OpenHAB::Core.full_version > Gem::Version.new("5.0.0.M1")
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_changed_event(*args)

    expect(event).not_to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be true
    expect(event.state).to be ON
    expect(event.was_null?).to be true
    expect(event.was_undef?).to be false
    expect(event.was?).to be false
    expect(event.was).to be_nil
  end

  it "has proper predicates for an UNDEF => ON event" do
    # @deprecated OH4.3 remove args and pass 5 arguments directly when dropping oh 4.3
    args = ["item", ON, UNDEF]
    args += [nil, nil] if OpenHAB::Core.full_version > Gem::Version.new("5.0.0.M1")
    event = OpenHAB::Core::Events::ItemEventFactory.create_state_changed_event(*args)

    expect(event).not_to be_null
    expect(event).not_to be_undef
    expect(event.state?).to be true
    expect(event.state).to be ON
    expect(event.was_null?).to be false
    expect(event.was_undef?).to be true
    expect(event.was?).to be false
    expect(event.was).to be_nil
  end
end
