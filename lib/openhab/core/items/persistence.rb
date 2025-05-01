# frozen_string_literal: true

require "delegate"

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      #
      # Items extensions to support
      # {https://www.openhab.org/docs/configuration/persistence.html openHAB's Persistence} feature.
      #
      # @see OpenHAB::DSL.persistence Persistence Block
      #
      # @example The following examples are based on these items
      #   Number        UV_Index
      #   Number:Power  Power_Usage "Power Usage [%.2f W]"
      #
      # @example Getting persistence data from the system default persistence service
      #   UV_Index.average_since(1.hour.ago)      # returns a DecimalType
      #   Power_Usage.average_since(12.hours.ago) # returns a QuantityType that corresponds to the item's type
      #
      # @example Querying a non-default persistence service
      #   UV_Index.average_since(1.hour.ago, :influxdb)
      #   Power_Usage.average_since(12.hours.ago, :rrd4j)
      #
      # @example Time of day shortcuts
      #   # Persistence methods accept any object that responds to #to_zoned_date_time, which includes
      #   # LocalTime, LocalDate, and Ruby's Time, Date, and DateTime.
      #   # This allows for easy querying of start of day
      #   logger.info Power_Usage.average_since(LocalTime::MIDNIGHT)
      #   logger.info Power_Usage.average_since(LocalDate.now)
      #   # Ruby's Date can be used too
      #   logger.info Power_Usage.average_since(Date.today)
      #
      #   # Yesterday
      #   logger.info Power_Usage.average_between(Date.today - 1, Date.today)
      #   # or
      #   logger.info Power_Usage.average_between(LocalDate.now - 1, LocalDate.now)
      #
      #   # When passing the local time, today's date is assumed
      #   logger.info Power_Usage.average_between(LocalTime.parse("4pm"), LocalTime.parse("9pm"))
      #   # or
      #   logger.info Power_Usage.average_between(Time.parse("4pm"), Time.parse("9pm"))
      #
      #   # Beware that Date, LocalDate, and LocalTime arithmetics will produce the same type, so
      #   Power_Usage.average_between(LocalTime.parse("4pm") - 1.day, LocalTime.parse("9pm") - 1.day)
      #   # Will still give you TODAY's data between 4pm and 9pm
      #   # To get yesterday's data, use Time.parse, i.e.
      #   Power_Usage.average_between(Time.parse("4pm") - 1.day, Time.parse("9pm") - 1.day)
      #
      # @example Comparison using Quantity
      #   # Because Power_Usage has a unit, the return value
      #   # from average_since is a QuantityType
      #   if Power_Usage.average_since(15.minutes.ago) > 5 | "kW"
      #     logger.info("The power usage exceeded its 15 min average)
      #   end
      #
      # @example PersistedState
      #   max = Power_Usage.maximum_since(LocalTime::MIDNIGHT)
      #   logger.info("Max power usage today: #{max}, at: #{max.timestamp})
      #
      module Persistence
        Item.prepend(self)

        #
        # A wrapper for {org.openhab.core.persistence.HistoricItem HistoricItem} that delegates to its state.
        #
        # A {PersistedState} object can be directly used in arithmetic operations with {State} and
        # other {PersistedState} objects.
        #
        # @example
        #   max = Power_Usage.maximum_since(LocalTime::MIDNIGHT)
        #   logger.info "Highest power usage: #{max} occurred at #{max.timestamp}" if max > 5 | "kW"
        #
        # @example Arithmetic operations
        #   todays_rate = Energy_Prices.persisted_state(Date.today) # Energy_Prices' unit is "<CURRENCY>/kWh"
        #   todays_cost = Daily_Energy_Consumption.state * todays_rate
        #
        class PersistedState < SimpleDelegator
          extend Forwardable

          # @!attribute [r] state
          # @return [Types::State]
          alias_method :state, :__getobj__

          # @!attribute [r] timestamp
          # @return [ZonedDateTime]

          # @!attribute [r] instant
          # @return [Instant] The timestamp as an Instant
          # @since openHAB 4.3

          # @!attribute [r] name
          # @return [String] Item name

          delegate %i[timestamp instant name] => :@historic_item

          def initialize(historic_item, state = nil)
            @historic_item = historic_item
            super(state || historic_item.state)
          end

          # @!visibility private
          def inspect
            "#<#{self.class} #{state} at: #{timestamp} item: #{name}>"
          end
        end

        # @deprecated Use {PersistedState} instead
        HistoricState = PersistedState

        # @!method average_since(timestamp, service = nil, riemann_type: nil)
        #   Returns the average value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The average value since `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method average_until(timestamp, service = nil, riemann_type: nil)
        #   Returns the average value of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The average value until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method average_between
        #   Returns the average value of the item's state between two points in time
        #
        #   @overload average_between(start, finish, service = nil, reimann_type: nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #
        #   @overload average_between(range, service = nil, reimann_type: nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #
        #   @return [DecimalType, QuantityType, nil] The average value between `start` and `finish`,
        #     or nil if no states could be found.
        #
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method delta_since(timestamp, service = nil)
        #   Returns the difference value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The difference value since `timestamp`,
        #     or nil if no previous states could be found.

        # @!method delta_until(timestamp, service = nil)
        #   Returns the difference value of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The difference value until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2

        # @!method delta_between
        #   Returns the difference value of the item's state between two points in time
        #
        #   @overload delta_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @overload delta_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [DecimalType, QuantityType, nil] The difference value between `start` and `finish`,
        #     or nil if no states could be found.

        # @!method deviation_since(timestamp, service = nil, riemann_type: nil)
        #   Returns the standard deviation of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The standard deviation since `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method deviation_until(timestamp, service = nil, riemann_type: nil)
        #   Returns the standard deviation of the item's state beetween now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The standard deviation until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method deviation_between
        #   Returns the standard deviation of the item's state between two points in time
        #
        #   @overload deviation_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #   @overload deviation_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [DecimalType, QuantityType, nil] The standard deviation between `start` and `finish`,
        #     or nil if no states could be found.
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method median_since(timestamp, service = nil)
        #   Returns the median of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The median since `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 4.3

        # @!method median_until(timestamp, service = nil)
        #   Returns the median of the item's state beetween now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The median until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.3

        # @!method median_between
        #   Returns the median of the item's state between two points in time
        #
        #   @overload median_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload median_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [DecimalType, QuantityType, nil] The median between `start` and `finish`,
        #     or nil if no states could be found.
        #   @since openHAB 4.3

        # @!method sum_since(timestamp, service = nil)
        #   Returns the sum of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The sum since `timestamp`,
        #     or nil if no previous states could be found.

        # @!method sum_until(timestamp, service = nil)
        #   Returns the sum of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The sum until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2

        # @!method sum_between
        #   Returns the sum of the item's state between two points in time
        #
        #   @overload sum_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload sum_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [DecimalType, QuantityType, nil] The sum between `start` and `finish`,
        #     or nil if no states could be found.

        # @!method variance_since(timestamp, service = nil, riemann_type: nil)
        #   Returns the variance of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The variance since `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method variance_until(timestamp, service = nil, riemann_type: nil)
        #   Returns the variance of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The variance until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method variance_between
        #   Returns the variance of the item's state between two points in time
        #
        #   @overload variance_between(start, finish, service = nil, reimann_type: nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #   @overload variance_between(range, service = nil, reimann_type: nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #
        #   @return [DecimalType, QuantityType, nil] The variance between `start` and `finish`,
        #     or nil if no states could be found.
        #   @since openHAB 5.0 riemann_type parameter added

        # @!method changed_since?(timestamp, service = nil)
        #   Whether the item's state has changed since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state has changed since the given `timestamp`, False otherwise.

        # @!method changed_until?(timestamp, service = nil)
        #   Whether the item's state has changed between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state has changed until the given `timestamp`, False otherwise.
        #   @since openHAB 4.2

        # @!method changed_between?
        #   Whether the item's state changed between two points in time
        #
        #   @overload changed_between?(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload changed_between?(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [true,false] True if the item's state changed between `start` and `finish`, False otherwise.

        # @!method evolution_rate(timestamp, service = nil)
        #   Returns the evolution rate of the item's state
        #   @return [DecimalType, nil] The evolution rate or nil if no previous state could be found.
        #   @deprecated This method has been deprecated in openHAB 4.2.
        #     Use {#evolution_rate_since} or {#evolution_rate_between} instead.
        #   @overload evolution_rate(timestamp, service = nil)
        #     Returns the evolution rate of the item's state since the given time
        #     @param [#to_zoned_date_time] timestamp The point in time from which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @return [DecimalType, nil] The evolution rate since `timestamp`,
        #       or nil if no previous state could be found.
        #     @deprecated In openHAB 4.2, use {#evolution_rate_since} instead
        #   @overload evolution_rate(start, finish, service = nil)
        #     Returns the evolution rate of the item's state between two points in time
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @return [DecimalType, nil] The evolution rate between `start` and `finish`,
        #       or nil if no previous state could be found.
        #     @deprecated In openHAB 4.2, use {#evolution_rate_between} instead

        # @!method evolution_rate_since(timestamp, service = nil)
        #   Returns the evolution rate of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, nil] The evolution rate since `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 4.2

        # @!method evolution_rate_until(timestamp, service = nil)
        #   Returns the evolution rate of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, nil] The evolution rate until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2

        # @!method evolution_rate_between
        #   Returns the evolution rate of the item's state between two points in time
        #
        #   @overload evolution_rate_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload evolution_rate_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [DecimalType, nil] The evolution rate between `start` and `finish`,
        #     or nil if no states could be found.
        #   @since openHAB 4.2

        # @!method historic_state(timestamp, service = nil)
        #   Returns the the item's state at the given time
        #   @param [#to_zoned_date_time] timestamp The point in time at which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [PersistedState, nil] The item's state at `timestamp`,
        #     or nil if no previous state could be found.
        #   @deprecated In openHAB 4.2, use {#persisted_state} instead

        # @!method persisted_state(timestamp, service = nil)
        #   Returns the the item's state at the given time
        #   @param [#to_zoned_date_time] timestamp The point in time at which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [PersistedState, nil] The item's state at `timestamp`,
        #     or nil if no state could be found.
        #   @since openHAB 4.2

        # @!method maximum_since(timestamp, service = nil)
        #   Returns the maximum value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [PersistedState, nil] The maximum value since `timestamp`,
        #     or nil if no previous states could be found.

        # @!method maximum_until(timestamp, service = nil)
        #   Returns the maximum value of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [PersistedState, nil] The maximum value until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2

        # @!method maximum_between
        #   Returns the maximum value of the item's state between two points in time
        #
        #   @overload maximum_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload maximum_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [PersistedState, nil] The maximum value between `start` and `finish`,
        #     or nil if no states could be found.

        # @!method minimum_since(timestamp, service = nil)
        #   Returns the minimum value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [PersistedState, nil] The minimum value since `timestamp`,
        #     or nil if no previous states could be found.

        # @!method minimum_until(timestamp, service = nil)
        #   Returns the minimum value of the item's state between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [PersistedState, nil] The minimum value until `timestamp`,
        #     or nil if no future states could be found.
        #   @since openHAB 4.2

        # @!method minimum_between
        #   Returns the minimum value of the item's state between two points in time
        #
        #   @overload minimum_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload minimum_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [PersistedState, nil] The minimum value between `start` and `finish`,
        #     or nil if no states could be found.

        # @!method updated_since?(timestamp, service = nil)
        #   Whether the item's state has been updated since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state has been updated since the given `timestamp`, False otherwise.

        # @!method updated_until?(timestamp, service = nil)
        #   Whether the item's state will be updated between now until the given time
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state will be updated until the given `timestamp`, False otherwise.
        #   @since openHAB 4.2

        # @!method updated_between?
        #   Whether the item's state was updated between two points in time
        #
        #   @overload updated_between?(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload updated_between?(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [true,false] True if the item's state was updated between `start` and `finish`, False otherwise.

        # @!method count_since(timestamp, service = nil)
        #   Returns the number of available historic data points from a point in time until now.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.

        # @!method count_until(timestamp, service = nil)
        #   Returns the number of available data points between now until the given time.
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.
        #   @since openHAB 4.2

        # @!method count_between
        #   Returns the number of available data points between two points in time.
        #
        #   @overload count_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload count_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [Integer] The number of values persisted for this item.

        # @!method count_state_changes_since(timestamp, service = nil)
        #   Returns the number of changes in historic data points from a point in time until now.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.

        # @!method count_state_changes_until(timestamp, service = nil)
        #   Returns the number of changes in data points between now until the given time.
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.
        #   @since openHAB 4.2

        # @!method count_state_changes_between
        #   Returns the number of changes in data points between two points in time.
        #
        #   @overload count_state_changes_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload count_state_changes_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [Integer] The number of values persisted for this item.

        # @!method all_states_since(timestamp, service = nil)
        #   Returns all the states from a point in time until now.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Array<PersistedState>] An array of {PersistedState} persisted for this item.
        #   @since openHAB 4.0

        # @!method all_states_until(timestamp, service = nil)
        #   Returns all the states between now until the given time.
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Array<PersistedState>] An array of {PersistedState} persisted for this item.
        #   @since openHAB 4.2

        # @!method all_states_between
        #   Returns all the states between two points in time.
        #
        #   @overload all_states_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload all_states_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [Array<PersistedState>] An array of {PersistedState} persisted for this item.
        #   @since openHAB 4.0

        # @!method riemann_sum_since(timestamp, service = nil, riemann_type: nil)
        #   Returns the Riemann sum of the states since a certain point in time.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The riemann sum since `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 5.0

        # @!method riemann_sum_until(timestamp, service = nil, riemann_type: nil)
        #   Returns the Riemann sum of the states between now until a certain point in time.
        #   @param [#to_zoned_date_time] timestamp The point in time until which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann sum.
        #     If nil, :left is used.
        #   @return [DecimalType, QuantityType, nil] The riemann sum until `timestamp`,
        #     or nil if no previous states could be found.
        #   @since openHAB 5.0

        # @!method riemann_sum_between
        #   Returns the Riemann sum of the states between two points in time.
        #
        #   @overload riemann_sum_between(start, finish, service = nil, riemann_type: nil)
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #   @overload riemann_sum_between(range, service = nil, riemann_type: nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @param [:left, :midpoint, :right, :trapezoidal] riemann_type An optional approximation type for Riemann
        #       sum. If nil, :left is used.
        #
        #   @return [DecimalType, QuantityType, nil] The riemann sum between `start` and `finish`,
        #     or nil if no previous states could be found.
        #   @since openHAB 5.0

        # @!method remove_all_states_since(timestamp, service = nil)
        #   Removes persisted data points since a certain point in time.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to remove
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [void]
        #   @since openHAB 4.2

        # @!method remove_all_states_until(timestamp, service = nil)
        #   Removes persisted data points from now until the given point in time.
        #   @param [#to_zoned_date_time] timestamp The point in time until which to remove
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [void]
        #   @since openHAB 4.2

        # @!method remove_all_states_between
        #   Removes persisted data points between two points in time.
        #
        #   @overload remove_all_states_between(start, finish, service = nil)
        #     @param [#to_zoned_date_time] start The point in time from which to remove
        #     @param [#to_zoned_date_time] finish The point in time to which to remove
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @overload remove_all_states_between(range, service = nil)
        #     @param [Range<#to_zoned_date_time>] range The time range to remove
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #
        #   @return [void]
        #   @since openHAB 4.2

        #
        # Persist item state to the persistence service
        #
        # @overload persist(service = nil)
        #   Persists the current state of the item
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [void]
        #
        # @overload persist(timestamp, state, service = nil)
        #   Persists a state at a given timestamp
        #   @param [#to_zoned_date_time] timestamp The timestamp for the given state to be stored
        #   @param [Types::State, #to_s] state The state to be stored
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [void]
        #   @since openHAB 4.2
        #
        # @overload persist(time_series, service = nil)
        #   Persists a time series
        #   @param [Types::TimeSeries] time_series The time series of states to be stored
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [void]
        #   @since openHAB 4.2
        #
        def persist(*args)
          # @deprecated OH 4.1 this if block content can be removed when dropping OH 4.1 support
          if Core.version < Core::V4_2
            raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..1)" if args.size > 1

            service = args.last || persistence_service
            Actions::PersistenceExtensions.persist(self, service&.to_s)
            return
          end

          first_arg = args.first
          if first_arg.is_a?(TimeSeries)
            if args.size > 2
              raise ArgumentError,
                    "wrong number of arguments to persist a time series (given #{args.size}, expected 1..2)"
            end

            service = args[1] || persistence_service
            Actions::PersistenceExtensions.java_send :persist,
                                                     [Item.java_class, Types::TimeSeries.java_class, java.lang.String],
                                                     self,
                                                     first_arg,
                                                     service&.to_s
          elsif first_arg.respond_to?(:to_zoned_date_time)
            unless args.size.between?(2, 3)
              raise ArgumentError, "wrong number of arguments to persist a state (given #{args.size}, expected 2..3)"
            end

            timestamp = first_arg.to_zoned_date_time
            state = format_update(args[1])
            service = args[2] || persistence_service
            Actions::PersistenceExtensions.java_send :persist,
                                                     [Item.java_class,
                                                      ZonedDateTime.java_class,
                                                      org.openhab.core.types.State,
                                                      java.lang.String],
                                                     self,
                                                     timestamp,
                                                     state,
                                                     service&.to_s

          else
            if args.size > 1
              raise ArgumentError,
                    "wrong number of arguments to persist the current state (given #{args.size}, expected 0..1)"
            end
            service = first_arg || persistence_service
            Actions::PersistenceExtensions.java_send :persist,
                                                     [Item.java_class, java.lang.String],
                                                     self,
                                                     service&.to_s

          end
        end

        # @!method last_update(service = nil)
        #   Returns the time the item was last updated.
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [ZonedDateTime, nil] The timestamp of the last update
        #   @see Item#last_state_update

        # @!method next_update(service = nil)
        #   Returns the first future update time of the item.
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [ZonedDateTime, nil] The timestamp of the next update
        #   @see last_update
        #   @since openHAB 4.2

        # @!method last_change(service = nil)
        #   Returns the time the item was last changed.
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [ZonedDateTime, nil] The timestamp of the last update
        #   @since openHAB 4.2
        #   @see Item#last_state_change

        # @!method next_change(service = nil)
        #   Returns the first future change time of the item.
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [ZonedDateTime, nil] The timestamp of the next update
        #   @see last_update
        #   @since openHAB 4.2

        %i[last_update next_update last_change next_change].each do |method|
          # @deprecated OH 4.1 remove this guard when dropping OH 4.1
          next unless Actions::PersistenceExtensions.respond_to?(method)

          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(service = nil)                            # def last_update(service = nil)
              service ||= persistence_service                       #   service ||= persistence_service
              result = Actions::PersistenceExtensions.#{method}(    #   result = Actions::PersistenceExtensions.last_update(
                self,                                               #     self,
                service&.to_s                                       #     service&.to_s
              )                                                     #   )
              wrap_result(result)                                   #   wrap_result(result)
            end                                                     # end
          RUBY
        end

        # @!method previous_state(service = nil, skip_equal: false)
        #   Return the previous state of the item
        #
        #   @param skip_equal [true,false] if true, skips equal state values and
        #          searches the first state not equal the current state
        #   @param service [String] the name of the PersistenceService to use
        #
        #   @return [PersistedState, nil] the previous state or nil if no previous state could be found,
        #           or if the default persistence service is not configured or
        #           does not refer to a valid service
        #
        #   @see Item#last_state

        # @!method next_state(service = nil, skip_equal: false)
        #   Return the next state of the item
        #
        #   @param skip_equal [true,false] if true, skips equal state values and
        #          searches the first state not equal the current state
        #   @param service [String] the name of the PersistenceService to use
        #
        #   @return [PersistedState, nil] the previous state or nil if no previous state could be found,
        #           or if the default persistence service is not configured or
        #           does not refer to a valid service
        #
        #   @since openHAB 4.2

        %i[previous_state next_state].each do |method|
          # @deprecated OH 4.1 remove this guard when dropping OH 4.1
          next unless Actions::PersistenceExtensions.respond_to?(method)

          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(service = nil, skip_equal: false)       # def previous_state(service = nil, skip_equal: false)
              service ||= persistence_service                     #   service ||= persistence_service
              result = Actions::PersistenceExtensions.#{method}(  #   result = Actions::PersistenceExtensions.previous_state(
                self,                                             #     self,
                skip_equal,                                       #     skip_equal,
                service&.to_s                                     #     service&.to_s
              )                                                   #   )
              wrap_result(result, quantify: true)                 #   wrap_result(result, quantify: true)
            end                                                   # end
          RUBY
        end

        class << self
          # @!visibility private
          def def_persistence_method(method, quantify: false, riemann_param: nil)
            method = method.to_s.dup
            suffix = method.delete_suffix!("?") && "?"
            riemann_arg = nil

            if riemann_param
              riemann_param = ", riemann_type: nil"
              # @deprecated OH4.3 remove if guard when dropping OH 4.3
              if Actions::PersistenceExtensions.const_defined?(:RiemannType)
                riemann_arg = "to_riemann_type(riemann_type),"
              end
            end

            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{method}#{suffix}(timestamp, service = nil#{riemann_param}) # def changed_since?(timestamp, service = nil, riemann_type: nil)
                service ||= persistence_service                                #   service ||= persistence_service
                result = Actions::PersistenceExtensions.#{method}(             #   result = Actions::PersistenceExtensions.average_since(
                  self,                                                        #     self,
                  timestamp.to_zoned_date_time,                                #     timestamp.to_zoned_date_time,
                  #{riemann_arg}                                               #     to_riemann_type(riemann_type),
                  service&.to_s                                                #     service&.to_s
                )                                                              #   )
                wrap_result(result, quantify: #{quantify})                     #   wrap_result(result, quantify: false)
              end                                                              # end
            RUBY
          end

          # @!visibility private
          def def_persistence_methods(method, quantify: false, riemann_param: nil)
            method = method.to_s.dup
            suffix = method.delete_suffix!("?") && "?"
            riemann_arg = nil

            def_persistence_method("#{method}_since#{suffix}", quantify:, riemann_param:)
            # @deprecated OH 4.1 remove if guard, keeping the content, when dropping OH 4.1
            if OpenHAB::Core.version >= OpenHAB::Core::V4_2
              def_persistence_method("#{method}_until#{suffix}", quantify:, riemann_param:)
            end

            if riemann_param
              riemann_param = ", riemann_type: nil"
              # @deprecated OH4.3 remove if guard when dropping OH 4.3
              if Actions::PersistenceExtensions.const_defined?(:RiemannType)
                riemann_arg = "to_riemann_type(riemann_type),"
              end
            end

            method = "#{method}_between"
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{method}#{suffix}(start, finish = nil, service = nil#{riemann_param})             # def changed_between?(start, finish, service = nil, riemann_type: nil)
                if start.is_a?(Range)                                                                #   if start.is_a?(Range)
                  raise ArgumentError, "wrong number of arguments (given 3, expected 2)" if service  #     raise ArgumentError, "wrong number of arguments (given 3, expected 2)" if service
                  service = finish                                                                   #     service = finish
                  finish = start.end                                                                 #     finish = start.end
                  start = start.begin                                                                #     start = start.begin
                end                                                                                  #   end
                service ||= persistence_service                                                      #   service ||= persistence_service
                result = Actions::PersistenceExtensions.#{method}(                                   #   result = Actions::PersistenceExtensions.average_between(
                  self,                                                                              #     self,
                  start.to_zoned_date_time,                                                          #     start.to_zoned_date_time,
                  finish.to_zoned_date_time,                                                         #     finish.to_zoned_date_time,
                  #{riemann_arg}                                                                     #     to_riemann_type(riemann_type),
                  service&.to_s                                                                      #     service&.to_s
                )                                                                                    #   )
                wrap_result(result, quantify: #{quantify})                                           #   wrap_result(result, quantify: false)
              end                                                                                    # end
            RUBY
          end
        end

        # arranged in alphabetical order
        def_persistence_methods(:average, quantify: true, riemann_param: true)
        def_persistence_methods(:changed?)
        def_persistence_methods(:count)

        def_persistence_methods(:count_state_changes)
        alias_method :state_changes_since, :count_state_changes_since
        alias_method :state_changes_until, :count_state_changes_until if OpenHAB::Core.version >= OpenHAB::Core::V4_2
        alias_method :state_changes_between, :count_state_changes_between

        def_persistence_methods(:delta, quantify: true)
        def_persistence_methods(:deviation, quantify: true, riemann_param: true)

        # @deprecated OH 4.2 - this still exists in OH 4.2 but logs a deprecation warning
        def_persistence_method(:historic_state, quantify: true)

        def_persistence_methods(:get_all_states, quantify: true)
        alias_method :all_states_since, :get_all_states_since
        alias_method :all_states_until, :get_all_states_until if OpenHAB::Core.version >= OpenHAB::Core::V4_2
        alias_method :all_states_between, :get_all_states_between

        def_persistence_methods(:maximum, quantify: true)
        def_persistence_methods(:minimum, quantify: true)
        def_persistence_methods(:median, quantify: true) if OpenHAB::Core.version >= OpenHAB::Core::V4_3
        # @deprecated OH4.3 remove if guard when dropping OH 4.3
        if Actions::PersistenceExtensions.const_defined?(:RiemannType)
          # riemann_sum methods were added in OH 5.0 which already quantifies the result in core
          def_persistence_methods(:riemann_sum, riemann_param: true)
        end
        def_persistence_methods(:sum, quantify: true)
        def_persistence_methods(:updated?)
        def_persistence_methods(:variance, quantify: true, riemann_param: true)

        if OpenHAB::Core.version >= OpenHAB::Core::V4_2
          def_persistence_method(:persisted_state) # already quantified in core

          def_persistence_methods(:evolution_rate)
          def_persistence_methods(:remove_all_states)
        end

        # @deprecated OH 4.2 this method is deprecated in OH 4.2 and may be removed in a future version
        def evolution_rate(start, finish_or_service = nil, service = nil)
          if service.nil?
            if finish_or_service.respond_to?(:to_zoned_date_time)
              service = persistence_service
              finish = finish_or_service
            else
              service = finish_or_service || persistence_service
              finish = nil
            end
          else
            finish = finish_or_service
          end

          if finish
            Actions::PersistenceExtensions.evolution_rate(
              self,
              start.to_zoned_date_time,
              finish.to_zoned_date_time,
              service&.to_s
            )
          else
            Actions::PersistenceExtensions.java_send :evolutionRate,
                                                     [Item.java_class, ZonedDateTime.java_class, java.lang.String],
                                                     self,
                                                     start.to_zoned_date_time,
                                                     service&.to_s
          end
        end

        private

        #
        # Convert value to QuantityType if it is a DecimalType and a unit is defined
        #
        # @param [Object] value The value to convert
        #
        # @return [Object] QuantityType or the original value
        #
        # @deprecated OH 4.1 in OH4.2, quantify is no longer needed because it is done inside core
        def quantify(value)
          if value.is_a?(DecimalType) && respond_to?(:unit) && unit
            logger.trace { "Unitizing #{value} with unit #{unit}" }
            QuantityType.new(value.to_big_decimal, unit)
          else
            value
          end
        end

        #
        # Wrap the result into a more convenient object type depending on the method and result.
        #
        # @param [Object] result the raw result type to be wrapped
        # @param [true, false] quantify whether to quantify the result
        #
        # @return [PersistedState] a {PersistedState} object if the result was a HistoricItem
        # @return [Array<PersistedState>] an array of {PersistedState} objects if the result was an array
        #   of HistoricItem
        # @return [QuantityType] a `QuantityType` object if the result was an average, delta, deviation,
        #   sum, or variance.
        # @return [Object] the original result object otherwise.
        #
        def wrap_result(result, quantify: false)
          case result
          when org.openhab.core.persistence.HistoricItem
            PersistedState.new(result, quantify ? quantify(result.state) : nil)
          when java.util.Collection, Array
            result.to_a.map { |historic_item| wrap_result(historic_item, quantify:) }
          else
            return quantify(result) if quantify

            result
          end
        end

        #
        # Get the specified persistence service from the current thread local variable
        #
        # @return [Object] Persistence service name as String or Symbol, or nil if not set
        #
        def persistence_service
          Thread.current[:openhab_persistence_service]
        end

        #
        # Convert a symbol to a RiemannType enum value
        # @param [Symbol] sym the symbol to convert
        # @return [RiemannType] the RiemannType enum value, or nil if sym is nil
        #
        def to_riemann_type(sym)
          Actions::PersistenceExtensions::RiemannType.value_of(sym.to_s.upcase) if sym
        end
      end
    end
  end
end
