# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      #
      # Contains methods for {OpenHAB::DSL.profile profile}'s callback to forward commands between items
      # and channels.
      #
      module ProfileCallback
        #
        # Forward the given command to the respective thing handler.
        #
        # @param [Command] command
        #
        def handle_command(command)
          link.channel.accepted_item_type&.then do |item_type|
            @dummy_channel_item ||= DSL::Items::ItemBuilder.item_factory.create_item(item_type, "")
            command = @dummy_channel_item.format_command(command) if @dummy_channel_item
          end
          super(command)
        end

        #
        # Send a command to the framework.
        #
        # @param [Command] command
        #
        def send_command(command)
          command = link.item.format_command(command)
          super(command)
        end

        #
        # Send a state update to the framework.
        #
        # @param [State] state
        #
        def send_update(state)
          state = link.item.format_update(state)
          super(state)
        end
      end
    end
  end
end
