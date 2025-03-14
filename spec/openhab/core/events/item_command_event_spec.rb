# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Events::ItemCommandEvent do
  it "is inspectable" do
    event = OpenHAB::Core::Events::ItemEventFactory.create_command_event("item", REFRESH, nil)
    expect(event.inspect).to eql "#<OpenHAB::Core::Events::ItemCommandEvent item=item command=REFRESH>"

    event = OpenHAB::Core::Events::ItemEventFactory.create_command_event("item", REFRESH, "source")
    expect(event.inspect).to eql '#<OpenHAB::Core::Events::ItemCommandEvent item=item command=REFRESH source="source">'
  end

  describe "predicates" do # rubocop:disable RSpec/EmptyExampleGroup -- examples are dynamically generated
    before do
      stub_const("PREDICATES",
                 %i[refresh?
                    on?
                    off?
                    increase?
                    decrease?
                    up?
                    down?
                    stop?
                    move?
                    play?
                    pause?
                    rewind?
                    fast_forward?
                    next?
                    previous?].freeze)
    end

    def self.test_command_predicate(command)
      it "has a predicate for #{command}" do
        predicate_method = PREDICATES.find { |pr| pr.to_s[0..3].delete("?").upcase == command.to_s[0..3] }
        event = OpenHAB::Core::Events::ItemEventFactory.create_command_event("item", command, nil)

        expect(event.send(predicate_method)).to be true
        other_predicates = PREDICATES - [predicate_method]
        expect(other_predicates.map { |pr| event.send(pr) }).to all(be false)
      end
    end

    test_command_predicate(REFRESH)
    test_command_predicate(ON)
    test_command_predicate(OFF)
    test_command_predicate(INCREASE)
    test_command_predicate(DECREASE)
    test_command_predicate(UP)
    test_command_predicate(DOWN)
    test_command_predicate(STOP)
    test_command_predicate(MOVE)
    test_command_predicate(PLAY)
    test_command_predicate(PAUSE)
    test_command_predicate(REWIND)
    test_command_predicate(FASTFORWARD)
    test_command_predicate(NEXT)
    test_command_predicate(PREVIOUS)
  end
end
