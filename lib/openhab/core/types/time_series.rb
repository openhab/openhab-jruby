# frozen_string_literal: true

require "forwardable"
require "openhab/core/lazy_array"

module OpenHAB
  module Core
    module Types
      TimeSeries = org.openhab.core.types.TimeSeries

      #
      # {TimeSeries} is used to transport a set of states together with their timestamp.
      #
      # The states are sorted chronologically. The entries can be accessed like an array.
      #
      # @since openHAB 4.1
      #
      # @example
      #   time_series = TimeSeries.new # defaults to :replace policy
      #                           .add(Time.at(2), DecimalType.new(2))
      #                           .add(Time.at(1), DecimalType.new(1))
      #                           .add(Time.at(3), DecimalType.new(3))
      #   logger.info "first entry: #{time_series.first.state}" # => 1
      #   logger.info "last entry: #{time_series.last.state}" # => 3
      #   logger.info "second entry: #{time_series[1].state}" # => 2
      #   logger.info "sum: #{time_series.sum(&:state)}" # => 6
      #
      # @see DSL::Rules::BuilderDSL#time_series_updated #time_series_updated rule trigger
      #
      class TimeSeries
        include LazyArray

        # @!attribute [r] policy
        #   Returns the persistence policy of this series.
        #   @see org.openhab.core.types.TimeSeries#getPolicy()
        #   @return [org.openhab.core.types.TimeSeries.Policy]

        # @!attribute [r] begin
        #   Returns the timestamp of the first element in this series.
        #   @return [Instant]

        # @!attribute [r] end
        #   Returns the timestamp of the last element in this series.
        #   @return [Instant]

        # @!attribute [r] size
        #   Returns the number of elements in this series.
        #   @return [Integer]

        #
        # Create a new instance of TimeSeries
        #
        # @param [:add, :replace, org.openhab.core.types.TimeSeries.Policy] policy
        #   The persistence policy of this series.
        #
        def initialize(policy = :replace)
          policy = Policy.value_of(policy.to_s.upcase) if policy.is_a?(Symbol)
          super
        end

        # Returns true if the series' policy is `ADD`.
        # @return [true,false]
        def add?
          policy == Policy::ADD
        end

        # Returns true if the series' policy is `REPLACE`.
        # @return [true,false]
        def replace?
          policy == Policy::REPLACE
        end

        # @!visibility private
        def inspect
          "#<OpenHAB::Core::Types::TimeSeries " \
            "policy=#{policy} " \
            "begin=#{self.begin} " \
            "end=#{self.end} " \
            "size=#{size}>"
        end

        # Explicit conversion to Array
        #
        # @return [Array]
        def to_a
          get_states.to_array.to_a.freeze
        end

        #
        # Returns the content of this series.
        # @return [Array<org.openhab.core.types.TimeSeries.Entry>]
        #
        def states
          to_a
        end

        # rename raw methods so we can overwrite them
        # @!visibility private
        alias_method :add_instant, :add

        #
        # Adds a new element to this series.
        #
        # Elements can be added in an arbitrary order and are sorted chronologically.
        #
        # @note This method returns self so it can be chained, unlike the Java version.
        #
        # @param [Instant, #to_zoned_date_time, #to_instant] timestamp An instant for the given state.
        # @param [State, String, Numeric] state The State at the given timestamp.
        #   If a String is given, it will be converted to {StringType}.
        #   If a {Numeric} is given, it will be converted to {DecimalType}.
        # @return [self]
        # @raise [ArgumentError] if state is not a {State}, String or {Numeric}
        #
        def add(timestamp, state)
          timestamp = to_instant(timestamp)
          state = format_state(state)
          add_instant(timestamp, state)
          self
        end

        #
        # Appends an entry to self, returns self
        #
        # @param [Array<Instant, State>] entry a two-element array with the timestamp and state.
        #   The timestamp can be an {Instant} or any object that responds to #to_zoned_date_time.
        # @return [self]
        #
        # @example Append an entry
        #   time_series << [Time.at(2), 2]
        #
        def <<(entry)
          raise ArgumentError, "entry must be an Array, but was #{entry.class}" unless entry.respond_to?(:to_ary)

          entry = entry.to_ary
          raise ArgumentError, "entry must be an Array of size 2, but was #{entry.size}" unless entry.size == 2

          add(entry[0], entry[1])
        end

        private

        def to_instant(timestamp)
          if timestamp.is_a?(Instant)
            timestamp
          elsif timestamp.respond_to?(:to_instant)
            timestamp.to_instant
          elsif timestamp.respond_to?(:to_zoned_date_time)
            timestamp.to_zoned_date_time.to_instant
          else
            raise ArgumentError, "timestamp must be an Instant, or convertible to one, but was #{timestamp.class}"
          end
        end

        def format_state(state)
          case state
          when State then state
          when String then StringType.new(state)
          when Numeric then DecimalType.new(state)
          else
            raise ArgumentError, "state must be a State, String or Numeric, but was #{state.class}"
          end
        end
      end
    end
  end
end

TimeSeries = OpenHAB::Core::Types::TimeSeries unless Object.const_defined?(:TimeSeries)
