# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      #
      # Contains methods for {OpenHAB::DSL.profile profile}'s callback to forward commands between items
      # and channels.
      #
      module ProfileCallback
        class << self
          # @!visibility private
          def dummy_channel_item(accepted_item_type)
            @dummy_channel_items[accepted_item_type]
          end
        end
        @dummy_channel_items = Hash.new do |hash, key|
          hash[key] = DSL::Items::ItemBuilder.item_factory.create_item(key, "")
        end

        #
        # Forward the given command to the respective thing handler.
        #
        # @param [Command] command
        #
        def handle_command(command)
          command = ProfileCallback.dummy_channel_item(link.channel.accepted_item_type)&.format_command(command)
          super
        end

        #
        # Send a command to the framework.
        #
        # @param [Command] command
        #
        def send_command(command)
          command = link.item.format_command(command)
          super
        end

        #
        # Send a state update to the framework.
        #
        # @param [State] state
        #
        def send_update(state)
          state = link.item.format_update(state)
          super
        end

        # @!method send_time_series(time_series)
        #   Send a time series to the framework.
        #   @param [TimeSeries] time_series
        #   @since openHAB 4.1
      end
    end
  end
end
