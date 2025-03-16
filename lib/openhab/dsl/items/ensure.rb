# frozen_string_literal: true

module OpenHAB
  module DSL
    module Items
      # Functionality to implement `ensure`/`ensure_states`
      module Ensure
        # Contains the `ensure` method mixed into {Item} and {GroupItem::Members}
        module Ensurable
          # Fluent method call that you can chain commands on to, that will
          # then automatically ensure that the item is not in the command's
          # state before sending the command.
          #
          # @example Turn switch on only if it's not on
          #   MySwitch.ensure.on
          # @example Turn on all switches in a group that aren't already on
          #   MySwitchGroup.members.ensure.on
          def ensure
            ItemDelegate.new(self)
          end
        end

        # Extensions for {::Item} to implement {Ensure}'s functionality
        #
        # @see OpenHAB::DSL::Items::Ensure::Ensurable#ensure ensure
        # @see OpenHAB::DSL.ensure_states ensure_states
        module Item
          include Ensurable

          Core::Items::Item.prepend(self)

          # If `ensure_states` is active (by block or chained method), then
          # check if this item is in the command's state before actually
          # sending the command
          %i[command update].each do |ensured_method|
            # rubocop:disable Style/IfUnlessModifier

            # def command(state, **kwargs)
            #   # immediately send the command if it's a command, but not a state (like REFRESH)
            #   return super(state, **kwargs) if state.is_a?(Command) && !state.is_a?(State)
            #   return super(state, **kwargs) unless Thread.current[:openhab_ensure_states]
            #
            #   formatted_state = format_command(state)
            #   logger.trace do
            #     "#{name} ensure #{state}, format_command: #{formatted_state}, current state: #{raw_state}"
            #   end
            #   return if raw_state == formatted_state
            #
            #   super(formatted_state, **kwargs)
            # end
            class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
              def #{ensured_method}(state, **kwargs)
                # immediately send the command if it's a command, but not a state (like REFRESH)
                #{"return super(state, **kwargs) if state.is_a?(Command) && !state.is_a?(State)" if ensured_method == :command}
                return super(state, **kwargs) unless Thread.current[:openhab_ensure_states]

                formatted_state = format_#{ensured_method}(state)
                logger.trace do
                  "\#{name} ensure \#{state}, format_#{ensured_method}: \#{formatted_state}, current state: \#{raw_state}"
                end
                return if raw_state.as(formatted_state.class) == formatted_state

                super(formatted_state, **kwargs)
              end
            RUBY
            # rubocop:enable Style/IfUnlessModifier
          end
        end

        # "anonymous" class that wraps any method call in `ensure_states`
        # before forwarding to the wrapped object
        # @!visibility private
        class ItemDelegate
          def initialize(item)
            @item = item
          end

          # @!visibility private
          # this is explicitly defined, instead of aliased, because #command
          # doesn't actually exist as a method, and will go through method_missing
          def <<(command)
            command(command)
          end

          # activate `ensure_states` before forwarding to the wrapped object
          def method_missing(method, ...)
            return super unless @item.respond_to?(method)

            DSL.ensure_states do
              @item.__send__(method, ...)
            end
          end

          # .
          def respond_to_missing?(method, include_private = false)
            @item.respond_to?(method, include_private) || super
          end
        end
      end

      Core::Items::GroupItem::Members.include(Ensure::Ensurable)
    end
  end
end
