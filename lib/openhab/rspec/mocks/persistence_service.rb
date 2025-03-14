# frozen_string_literal: true

module OpenHAB
  module RSpec
    module Mocks
      class PersistenceService
        include org.openhab.core.persistence.ModifiablePersistenceService
        include Singleton

        OPERATOR_TO_SYMBOL = {
          EQ: :==,
          NEQ: :!=,
          GT: :>,
          LT: :<,
          GTE: :>=,
          LTE: :<=
        }.freeze

        class HistoricItem
          include org.openhab.core.persistence.HistoricItem

          attr_reader :timestamp, :instant, :state, :name

          def initialize(timestamp, state, name)
            @timestamp = timestamp
            @state = state
            @name = name
            @instant = @timestamp.to_instant
          end
        end

        module PersistedState
          def timestamp
            # PersistenceExtensions uses an anonymous class to wrap the current
            # state if that happens to be an answer. Except it calls
            # ZonedDateTime.now in Java land, bypassing Timecop.
            # Detect that and make the call in Ruby
            #
            jc = @historic_item.class.java_class
            return ZonedDateTime.now if jc.anonymous? && jc.enclosing_class == PersistenceExtensions.java_class

            super
          end
        end
        Core::Items::Persistence::PersistedState.prepend(PersistedState)

        attr_reader :id

        def initialize
          @id = "default"
          reset
        end

        def reset
          @data = Hash.new { |h, k| h[k] = [] }
        end

        def store(item, date = nil, state = nil, item_alias = nil)
          if date.is_a?(String) # alias overload
            item_alias = date
            date = nil
          end
          state ||= item.state
          date ||= ZonedDateTime.now
          item_alias ||= item.name

          new_item = HistoricItem.new(date, state, item.name)

          item_history = @data[item_alias]

          insert_index = item_history.bsearch_index do |i|
            i.timestamp.compare_to(date).positive?
          end

          return item_history << new_item unless insert_index

          return item_history[insert_index].state = state if item_history[insert_index].timestamp == date

          item_history.insert(insert_index, new_item)
        end

        def remove(filter, _alias = nil)
          query_internal(filter) do |item_history, index|
            historic_item = item_history.delete_at(index)
            @data.delete(historic_item.name) if item_history.empty?
          end
          true
        end

        def query(filter, _alias = nil)
          result = []

          query_internal(filter) do |item_history, index|
            result << item_history[index]

            return result if filter.page_number.zero? && result.length == filter.page_size && filter.item_name
          end

          result.sort_by!(&:timestamp) unless filter.item_name

          result = result.slice(filter.page_number * filter.page_size, filter.page_size) unless filter.page_number.zero?

          result
        end

        def get_item_info # rubocop:disable Naming/AccessorMethodName -- must match Java interface
          @data.to_set do |(n, entries)|
            [n, entries.length, entries.first.timestamp, entries.last.timestamp]
          end
        end

        def get_default_strategies # rubocop:disable Naming/AccessorMethodName -- must match Java interface
          [org.openhab.core.persistence.strategy.PersistenceStrategy::Globals::CHANGE]
        end

        private

        def query_internal(filter, &)
          if filter.item_name
            return unless @data.key?(filter.item_name)

            query_item_internal(@data[filter.item_name], filter, &)
          else
            @data.each_value do |item_history|
              query_item_internal(item_history, filter, &)
            end
          end
        end

        def query_item_internal(item_history, filter)
          first_index = 0
          last_index = item_history.length

          if filter.begin_date
            first_index = item_history.bsearch_index do |i|
              i.timestamp.compare_to(filter.begin_date).positive?
            end
            return if first_index.nil?
          end

          if filter.end_date
            last_index = item_history.bsearch_index do |i|
              i.timestamp.compare_to(filter.end_date).positive?
            end
            return if last_index&.zero?

            last_index ||= item_history.length
          end

          range = first_index...last_index

          operator = OPERATOR_TO_SYMBOL[filter.operator]
          block = lambda do |i|
            next if filter.state && !item_history[i].state.send(operator, filter.state)

            yield(item_history, i)
          end

          if filter.ordering == filter.class::Ordering::DESCENDING
            range.reverse_each(&block)
          else
            range.each(&block)
          end
        end
      end
    end
  end
end
