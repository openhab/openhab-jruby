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
      # @example Comparison using Quantity
      #   # Because Power_Usage has a unit, the return value
      #   # from average_since is a QuantityType which can be
      #   # compared against a string with quantity
      #   if Power_Usage.average_since(15.minutes.ago) > 5 | "kW"
      #     logger.info("The power usage exceeded its 15 min average)
      #   end
      #
      # @example HistoricState
      #   max = Power_Usage.maximum_since(LocalTime::MIDNIGHT)
      #   logger.info("Max power usage today: #{max}, at: #{max.timestamp})
      #
      module Persistence
        GenericItem.prepend(self)

        #
        # A state class with an added timestamp attribute.
        #
        # This wraps {org.openhab.core.persistence.HistoricItem HistoricItem}
        # to allow implicitly treating the object as its state, and wrapping of
        # that state into a {QuantityType} as necessary.
        #
        class HistoricState < SimpleDelegator
          # @!attribute [r] state
          # @return [Types::State]
          alias_method :state, :__getobj__

          def initialize(state, historic_item)
            @historic_item = historic_item
            super(state)
          end

          # @!attribute [r] timestamp
          # @return [ZonedDateTime]
          def timestamp
            @historic_item.timestamp
          end
        end

        # All persistence methods that could return a QuantityType
        QUANTITY_METHODS = %i[average_since
                              delta_since
                              deviation_since
                              sum_since
                              variance_since].freeze

        # All persistence methods that require a timestamp
        # Note the _between methods are automatically created from the _since methods
        PERSISTENCE_METHODS = (QUANTITY_METHODS +
                              %i[changed_since?
                                 count_since
                                 count_state_changes_since
                                 historic_state
                                 maximum_since
                                 minimum_since
                                 updated_since?]).freeze
        private_constant :QUANTITY_METHODS, :PERSISTENCE_METHODS

        # @!method persist(service = nil)
        #   Persists the state of the item
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [void]

        # @!method last_update(service = nil)
        #   Returns the time the item was last updated.
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [ZonedDateTime, nil] The timestamp of the last update

        # @!method average_since(timestamp, service = nil)
        #   Returns the average value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The average value since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method average_between(start, finish, service = nil)
        #   Returns the average value of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The average value between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method delta_since(timestamp, service = nil)
        #   Returns the difference value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The difference value since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method delta_between(start, finish, service = nil)
        #   Returns the difference value of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The difference value between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method deviation_since(timestamp, service = nil)
        #   Returns the standard deviation of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The standard deviation since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method deviation_between(start, finish, service = nil)
        #   Returns the standard deviation of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The standard deviation between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method sum_since(timestamp, service = nil)
        #   Returns the sum of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The sum since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method sum_between(start, finish, service = nil)
        #   Returns the sum of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The sum between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method variance_since(timestamp, service = nil)
        #   Returns the variance of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The variance since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method variance_between(start, finish, service = nil)
        #   Returns the variance of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [DecimalType, QuantityType, nil] The variance between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method changed_since?(timestamp, service = nil)
        #   Whether the item's state has changed since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state has changed since the given `timestamp`, False otherwise.

        # @!method changed_between?(start, finish, service = nil)
        #   Whether the item's state changed between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state changed between `start` and `finish`, False otherwise.

        # @!method evolution_rate(timestamp, service = nil)
        #   Returns the evolution rate of the item's state
        #   @return [DecimalType, QuantityType, nil] The evolution rate since `timestamp`,
        #     or nil if no previous state could be found.
        #   @overload evolution_rate(timestamp, service = nil)
        #     Returns the evolution rate of the item's state since the given time
        #     @param [#to_zoned_date_time] timestamp The point in time from which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @return [DecimalType, QuantityType, nil] The evolution rate since `timestamp`,
        #       or nil if no previous state could be found.
        #   @overload evolution_rate(start, finish, service = nil)
        #     Returns the evolution rate of the item's state between two points in time
        #     @param [#to_zoned_date_time] start The point in time from which to search
        #     @param [#to_zoned_date_time] finish The point in time to which to search
        #     @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #     @return [DecimalType, QuantityType, nil] The evolution rate between `start` and `finish`,
        #       or nil if no previous state could be found.

        # @!method historic_state(timestamp, service = nil)
        #   Returns the the item's state at the given time
        #   @param [#to_zoned_date_time] timestamp The point in time at which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [HistoricState, nil] The item's state at `timestamp`,
        #     or nil if no previous state could be found.

        # @!method maximum_since(timestamp, service = nil)
        #   Returns the maximum value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [HistoricState, nil] The maximum value since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method maximum_between(start, finish, service = nil)
        #   Returns the maximum value of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [HistoricState, nil] The maximum value between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method minimum_since(timestamp, service = nil)
        #   Returns the minimum value of the item's state since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [HistoricState, nil] The minimum value since `timestamp`,
        #     or nil if no previous state could be found.

        # @!method minimum_between(start, finish, service = nil)
        #   Returns the minimum value of the item's state between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [HistoricState, nil] The minimum value between `start` and `finish`,
        #     or nil if no previous state could be found.

        # @!method updated_since?(timestamp, service = nil)
        #   Whether the item's state has been updated since the given time
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state has been updated since the given `timestamp`, False otherwise.

        # @!method updated_between?(start, finish, service = nil)
        #   Whether the item's state was updated between two points in time
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [true,false] True if the item's state was updated between `start` and `finish`, False otherwise.

        # @!method count_since(timestamp, service = nil)
        #   Returns the number of available historic data points from a point in time until now.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.

        # @!method count_between(start, finish, service = nil)
        #   Returns the number of available historic data points between two points in time.
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.

        # @!method count_state_changes_since(timestamp, service = nil)
        #   Returns the number of changes in historic data points from a point in time until now.
        #   @param [#to_zoned_date_time] timestamp The point in time from which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.

        # @!method count_state_changes_between(start, finish, service = nil)
        #   Returns the number of changes in historic data points between two points in time.
        #   @param [#to_zoned_date_time] start The point in time from which to search
        #   @param [#to_zoned_date_time] finish The point in time to which to search
        #   @param [Symbol, String] service An optional persistence id instead of the default persistence service.
        #   @return [Integer] The number of values persisted for this item.

        %i[persist last_update].each do |method|
          define_method(method) do |service = nil|
            service ||= persistence_service
            Actions::PersistenceExtensions.public_send(method, self, service&.to_s)
          end
        end

        #
        # Return the previous state of the item
        #
        # @param skip_equal [true,false] if true, skips equal state values and
        #        searches the first state not equal the current state
        # @param service [String] the name of the PersistenceService to use
        #
        # @return [HistoricState, nil] the previous state or nil if no previous state could be found,
        #         or if the default persistence service is not configured or
        #         does not refer to a valid service
        #
        def previous_state(service = nil, skip_equal: false)
          service ||= persistence_service
          result = Actions::PersistenceExtensions.previous_state(self, skip_equal, service&.to_s)
          HistoricState.new(quantify(result.state), result) if result
        end

        PERSISTENCE_METHODS.each do |method|
          define_method(method) do |timestamp, service = nil|
            service ||= persistence_service
            result = Actions::PersistenceExtensions.public_send(
              method.to_s.delete_suffix("?"),
              self,
              timestamp.to_zoned_date_time,
              service&.to_s
            )
            wrap_result(result, method)
          end

          next unless /_since\??$/.match?(method.to_s)

          between_method = method.to_s.sub("_since", "_between").to_sym
          define_method(between_method) do |start, finish, service = nil|
            service ||= persistence_service
            result = Actions::PersistenceExtensions.public_send(
              between_method.to_s.delete_suffix("?"),
              self,
              start.to_zoned_date_time,
              finish.to_zoned_date_time,
              service&.to_s
            )
            wrap_result(result, method)
          end
        end

        # evolution_rate's "between" method is overloaded with the same name
        method = :evolution_rate
        define_method(method) do |start, finish_or_service = nil, service = nil|
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

          result = if finish
                     Actions::PersistenceExtensions.public_send(
                       method,
                       self,
                       start.to_zoned_date_time,
                       finish.to_zoned_date_time,
                       service&.to_s
                     )
                   else
                     Actions::PersistenceExtensions.public_send(
                       method,
                       self,
                       start.to_zoned_date_time,
                       service&.to_s
                     )
                   end
          wrap_result(result, method)
        end

        alias_method :state_changes_since, :count_state_changes_since
        alias_method :state_changes_between, :count_state_changes_between

        private

        #
        # Convert value to QuantityType if it is a DecimalType and a unit is defined
        #
        # @param [Object] value The value to convert
        #
        # @return [Object] QuantityType or the original value
        #
        def quantify(value)
          if value.is_a?(DecimalType) && respond_to?(:unit) && unit
            logger.trace("Unitizing #{value} with unit #{unit}")
            QuantityType.new(value.to_big_decimal, unit)
          else
            value
          end
        end

        #
        # Wrap the result into a more convenient object type depending on the method and result.
        #
        # @param [Object] result the raw result type to be wrapped
        # @param [Symbol] method the name of the called method
        #
        # @return [HistoricState] a {HistoricState} object if the result was a HistoricItem
        # @return [QuantityType] a `QuantityType` object if the result was an average, delta, deviation,
        #                        sum, or variance.
        # @return [Object] the original result object otherwise.
        #
        def wrap_result(result, method)
          if result.is_a?(org.openhab.core.persistence.HistoricItem)
            return HistoricState.new(quantify(result.state), result)
          end
          return quantify(result) if QUANTITY_METHODS.include?(method)

          result
        end

        #
        # Get the specified persistence service from the current thread local variable
        #
        # @return [Object] Persistence service name as String or Symbol, or nil if not set
        #
        def persistence_service
          Thread.current[:openhab_persistence_service]
        end
      end
    end
  end
end
