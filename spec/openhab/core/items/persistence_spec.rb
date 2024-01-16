# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::Persistence do
  def test_all_methods(item)
    item.persist

    Timecop.travel(1.second)

    item.persist

    Timecop.travel(1.second)

    expect do
      since_methods =
        %i[
          average_since
          changed_since?
          delta_since
          deviation_since
          evolution_rate
          historic_state
          maximum_since
          minimum_since
          sum_since
          updated_since?
          variance_since
        ]
      # @deprecated OH3.4
      since_methods << :all_states_since if OpenHAB::Core.version >= OpenHAB::Core::V4_0
      since_methods.each do |method|
        item.__send__(method, 1.minute.ago)
        item.__send__(method, 1.minute.ago, :influxdb)
      end

      between_methods = %i[
        average_between
        changed_between?
        delta_between
        deviation_between
        evolution_rate
        maximum_between
        minimum_between
        sum_between
        updated_between?
        variance_between
      ]
      # @deprecated OH3.4
      between_methods << :all_states_between if OpenHAB::Core.version >= OpenHAB::Core::V4_0
      between_methods.each do |method|
        item.__send__(method, 2.minutes.ago, Time.now)
        item.__send__(method, 2.minutes.ago, Time.now, :influxdb)
      end
    end.not_to raise_error
  end

  it "supports all persistence methods on a NumberItem" do
    test_all_methods(items.build { number_item "Number1", state: 10 })
  end

  it "supports all persistence methods on a non-NumberItem Item" do
    test_all_methods(items.build { switch_item "Switch1", state: ON })
  end

  it "handles persistence data with units of measurement" do
    items.build { number_item "Number_Power", state: 3 | "kW" }
    Number_Power.persist
    expect(Number_Power.maximum_since(10.seconds.ago)).to eql(3 | "kW")
  end

  it "handles persistence data on plain number item" do
    items.build { number_item "Number1", state: 3 }
    Number1.persist
    expect(Number1.maximum_since(10.seconds.ago)).to eq 3
  end

  it "HistoricState directly returns a timestamp" do
    Timecop.freeze
    items.build { number_item "Number1", state: 3 }
    Number1.persist
    max = Number1.maximum_since(10.seconds.ago)
    expect(max.timestamp).to eq Time.now
    expect(max).to eq max.state
  end

  # @deprecated OH3.4
  if OpenHAB::Core.version >= OpenHAB::Core::V4_0
    describe "all_states_since and all_states_between" do
      before do
        items.build { number_item Number1, state: 10 }
        Number1.persist
        Timecop.travel(1.second)
        Number1.persist
      end

      let(:all_result) do
        [Number1.all_states_since(2.seconds.ago), Number1.all_states_between(5.seconds.ago, 1.ms.ago)]
      end

      it "return an array" do
        expect(all_result).to all(be_an(Array))
      end

      it "return a HistoricState as the array element" do
        expect(all_result).to all(all(respond_to(:timestamp)))
        expect(all_result).to all(all(respond_to(:state)))
        expect(all_result).to all(all(be_an(OpenHAB::Core::Items::Persistence::HistoricState)))
      end
    end
  end
end
