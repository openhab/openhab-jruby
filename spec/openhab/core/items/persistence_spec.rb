# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::Persistence do
  # Call the given method with no arguments
  def call_method0(item, method)
    item.public_send(method)
    item.public_send(method, :influxdb)
  end

  # Call the given method with one timestamp argument
  def call_method1(item, method)
    item.public_send(method, 1.minute.ago)
    item.public_send(method, 1.minute.ago, :influxdb)
  end

  # Call the given method with two timestamp arguments
  def call_method2(item, method)
    item.public_send(method, 2.minutes.ago, Time.now)
    item.public_send(method, 2.minutes.ago, Time.now, :influxdb)
  end

  # Call the given method with _since, _until_, and _between suffixes
  def call_variants(item, method)
    method = method.to_s.dup
    suffix = method.delete_suffix!("?") && "?"

    call_method1(item, "#{method}_since#{suffix}")
    call_method1(item, "#{method}_until#{suffix}") if OpenHAB::Core.version >= OpenHAB::Core::V4_2

    method = "#{method}_between#{suffix}"
    call_method2(item, method)
  end

  def call_all_methods(item)
    item.persist
    Timecop.travel(1.second)
    item.persist
    Timecop.travel(1.second)

    {
      all_states: { type: :variants, since: OpenHAB::Core::V4_0 },
      average: { type: :variants },
      changed?: { type: :variants },
      count: { type: :variants },
      count_state_changes: { type: :variants },
      delta: { type: :variants },
      deviation: { type: :variants },
      evolution_rate: { type: :variants, since: OpenHAB::Core::V4_2 },
      historic_state: { type: :method1 }, # @deprecated OH 4.2
      last_update: { type: :method0 },
      maximum: { type: :variants },
      minimum: { type: :variants },
      next_state: { type: :method0, since: OpenHAB::Core::V4_2 },
      next_update: { type: :method0, since: OpenHAB::Core::V4_2 },
      persisted_state: { type: :method1, since: OpenHAB::Core::V4_2 },
      previous_state: { type: :method0 },
      remove_all_states: { type: :variants, since: OpenHAB::Core::V4_2 },
      sum: { type: :variants },
      updated?: { type: :variants },
      variance: { type: :variants }
    }.each do |method, config|
      next if config[:since]&.>(OpenHAB::Core.version)

      case config[:type]
      when :method0 then call_method0(item, method)
      when :method1 then call_method1(item, method)
      when :variants then call_variants(item, method)
      else raise "Unknown method type #{config[:type]} for #{method}"
      end
    end

    # Special case for the "evolution_rate" method which has been superseded
    # by evolution_rate_since/until/between in openHAB 4.2
    call_method1(item, :evolution_rate)

    # test the "between" variant of evolution_rate
    call_method2(item, :evolution_rate)
  end

  it "supports all persistence methods on a NumberItem" do
    expect do
      call_all_methods(items.build { number_item "Number1", state: 10 })
    end.not_to raise_error
  end

  it "supports all persistence methods on a non-NumberItem Item" do
    expect do
      call_all_methods(items.build { switch_item "Switch1", state: ON })
    end.not_to raise_error
  end

  describe "#evolution_rate" do
    it "returns a DecimalType" do
      item = items.build { number_item "Number_Power", state: 3 | "kW" }
      Timecop.freeze
      item.persist
      Timecop.travel(1.second)
      item.persist
      expect(item.evolution_rate(1.second.ago)).to be_a(DecimalType)
    end
  end

  describe "#persist" do
    let(:item) { items.build { number_item "Number1", state: 10 } }

    it "works" do
      item.persist
      item.persist(:influxdb)
    end

    # @deprecated OH 4.1 Remove if guard when dropping oh 4.1 support
    if OpenHAB::Core.version >= OpenHAB::Core::V4_2
      it "supports persisting a state with a timestamp" do
        item.persist(Time.now - 1.minute, 5)
        item.persist(Time.now - 1.minute, 5, :influxdb)
      end

      it "supports persisting a time series" do
        item.persist(TimeSeries.new)
        item.persist(TimeSeries.new, :influxdb)
      end
    end
  end

  it "handles persistence data with units of measurement" do
    items.build { number_item "Number_Power", state: 3 | "kW" }
    Number_Power.persist
    expect(Number_Power.maximum_since(10.seconds.ago)).to eql(3 | "kW")
    expect(Number_Power.maximum_until(10.seconds.ago)).to eql(3 | "kW") if Number_Power.respond_to?(:maximum_until)
    expect(Number_Power.maximum_between(10.seconds.ago, Time.now)).to eql(3 | "kW")
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
