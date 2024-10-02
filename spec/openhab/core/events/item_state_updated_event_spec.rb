# frozen_string_literal: true

if OpenHAB::Core::Events.const_defined?(:ItemStateUpdatedEvent) # @deprecated OH3.4 - remove if
  RSpec.describe OpenHAB::Core::Events::ItemStateUpdatedEvent do
    it "is inspectable" do
      event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", NULL, nil)
      expect(event.inspect).to eql "#<OpenHAB::Core::Events::ItemStateUpdatedEvent item=item state=NULL>"

      event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", NULL, "source")
      expect(event.inspect).to eql(
        '#<OpenHAB::Core::Events::ItemStateUpdatedEvent item=item state=NULL source="source">'
      )
    end

    it "has proper predicates for a NULL event" do
      event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", NULL)

      expect(event).to be_null
      expect(event).not_to be_undef
      expect(event.state?).to be false
      expect(event.state).to be_nil
    end

    it "has proper predicates for an UNDEF event" do
      event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", UNDEF)

      expect(event).not_to be_null
      expect(event).to be_undef
      expect(event.state?).to be false
      expect(event.state).to be_nil
    end

    it "has proper predicates for an ON event" do
      event = OpenHAB::Core::Events::ItemEventFactory.create_state_updated_event("item", ON)

      expect(event).not_to be_null
      expect(event).not_to be_undef
      expect(event.state?).to be true
      expect(event.state).to be ON
    end
  end
end
