# frozen_string_literal: true

module OpenHAB
  module Core
    module Events
      java_import org.openhab.core.items.events.ItemTimeSeriesUpdatedEvent

      #
      # {AbstractEvent} sent when an item received a time series update.
      #
      # @!attribute [r] time_series
      #   @return [TimeSeries] The updated time series.
      #
      # @since openHAB 4.1
      # @see DSL::Rules::BuilderDSL#time_series_updated #time_series_updated rule trigger
      #
      class ItemTimeSeriesUpdatedEvent < ItemEvent; end
    end
  end
end
