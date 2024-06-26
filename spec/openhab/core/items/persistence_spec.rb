# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::Persistence do
  # Call the given method with no arguments
  def call_with_no_args(method, item)
    item.public_send(method, :influxdb)
    item.public_send(method)
  end

  # Call the given method with one timestamp argument
  def call_with_one_arg(method, item)
    timestamp = method.to_s.include?("until") ? 2.seconds.from_now : 2.seconds.ago
    item.public_send(method, timestamp, :influxdb)
    item.public_send(method, timestamp)
  end

  # Call the given method with two timestamp arguments
  def call_with_two_args(method, item)
    item.public_send(method, 2.seconds.ago, Time.now, :influxdb)
    item.public_send(method, 2.seconds.ago, Time.now)
  end

  def call_method(method, item)
    if method.to_s.include?("between")
      call_with_two_args(method, item)
    else
      call_with_one_arg(method, item)
    end
  end

  # Freeze time to avoid intermittent timing issues esp. with #delta_since
  before { Timecop.freeze }

  let(:dimensionless_item) do
    items.build { number_item "DimensionlessItem", state: 10 }.tap do |item|
      item.persist
      time_travel_and_execute_timers(1.second)
      item.persist
      time_travel_and_execute_timers(1.second)
      item.persist
    end
  end

  let(:dimensioned_item) do
    items.build { number_item "DimensionedItem", state: 10 | "kW" }.tap do |item|
      item.persist
      time_travel_and_execute_timers(1.second)
      item.persist
      time_travel_and_execute_timers(1.second)
      item.persist
    end
  end

  %i[last_update next_update last_change next_change previous_state next_state].each do |method|
    next unless OpenHAB::Core::Actions::PersistenceExtensions.respond_to?(method)

    describe "##{method}" do
      it "works" do
        call_with_no_args(method, dimensionless_item)
      end
    end
  end

  # @deprecated OH 4.2 historic_state is deprecated in OH 4.2 and may be removed in future versions
  %i[persisted_state historic_state].each do |method|
    next unless OpenHAB::Core::Actions::PersistenceExtensions.respond_to?(method)

    describe "##{method}" do
      it "works" do
        call_with_one_arg(method, dimensionless_item)
      end
    end
  end

  numeric_methods = %i[average delta deviation maximum minimum sum variance]
  variants = %i[since until between]
  %i[
    all_states
    average
    changed?
    count
    count_state_changes
    delta
    deviation
    evolution_rate
    maximum
    minimum
    remove_all_states
    sum
    updated?
    variance
  ].product(variants).each do |name, variant|
    prefix = name.to_s
    suffix = prefix.delete_suffix!("?") && "?"
    method = :"#{prefix}_#{variant}#{suffix}"
    next unless OpenHAB::Core::Items::Persistence.instance_methods.include?(method)

    describe "##{method}" do
      # @deprecate OH 4.1 - OH 4.2+ core returns QuantityType when applicable, so we don't have to quantify
      if OpenHAB::Core.version < OpenHAB::Core::V4_2 && numeric_methods.include?(name)
        it "returns a QuantityType on a dimensioned NumberItem" do
          result = call_method(method, dimensioned_item)
          result = result.state if result.is_a?(OpenHAB::Core::Items::Persistence::PersistedState)
          expect(result).to be_a(QuantityType)
        end

        it "returns a DecimalType on a dimensionless NumberItem" do
          result = call_method(method, dimensionless_item)
          result = result.state if result.is_a?(OpenHAB::Core::Items::Persistence::PersistedState)
          expect(result).to be_a(DecimalType)
        end
      else
        it "works" do
          call_method(method, dimensionless_item)
        end
      end

      if name == :all_states
        it "returns an array of PersistedState" do
          result = call_method(method, dimensionless_item)
          expect(result).to all(be_an(OpenHAB::Core::Items::Persistence::PersistedState))
        end
      end
    end
  end

  # @deprecated OH 4.2  evolution_rate is deprecated in OH 4.2 and may be removed in future versions
  describe "#evolution_rate", if: OpenHAB::Core.version <= OpenHAB::Core::V4_2 do
    it "returns a DecimalType" do
      expect(dimensionless_item.evolution_rate(2.seconds.ago)).to be_a(DecimalType)
      # expect(dimensionless_item.evolution_rate(2.seconds.ago, Time.now)).to be_a(DecimalType)
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
      it "accepts a timestamp and a state" do
        item.persist(Time.now - 1.minute, 5)
        item.persist(Time.now - 1.minute, 5, :influxdb)
      end

      it "raises an error when given a timestamp with a missing state" do
        expect { item.persist(Time.now) }.to raise_error(ArgumentError)
      end

      it "accepts a TimeSeries" do
        item.persist(TimeSeries.new)
        item.persist(TimeSeries.new, :influxdb)
      end
    end
  end

  it "PersistedState directly returns a state" do
    items.build { number_item "Number1", state: 3 }
    Number1.persist
    max = Number1.maximum_since(10.seconds.ago)
    expect(max).to eql max.state
    expect(max.timestamp).to be_a ZonedDateTime
  end
end
