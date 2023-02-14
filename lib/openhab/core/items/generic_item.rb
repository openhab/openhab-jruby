# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.items.GenericItem

      #
      # The abstract base class for all items.
      #
      # @see org.openhab.core.items.GenericItem
      #
      class GenericItem
        # @!parse include Item

        # rubocop:disable Naming/MethodName these mimic Java fields, which are
        # actually methods
        class << self
          # manually define this, since the Java side doesn't
          # @!visibility private
          def ACCEPTED_COMMAND_TYPES
            [org.openhab.core.types.RefreshType.java_class].freeze
          end

          # manually define this, since the Java side doesn't
          # @!visibility private
          def ACCEPTED_DATA_TYPES
            [org.openhab.core.types.UnDefType.java_class].freeze
          end

          # @!visibility private
          #
          # Override to support {Proxy}
          #
          # Item.=== isn't actually included (on the Ruby side) into
          # {GenericItem}
          #
          def ===(other)
            other.is_a?(self)
          end
        end
        # rubocop:enable Naming/MethodName

        # @!attribute [r] name
        #   The item's name.
        #   @return [String]

        # @!attribute [r] label
        #   The item's descriptive label.
        #   @return [String, nil]

        # @!visibility private
        alias_method :hash, :hash_code

        # @!attribute [r] raw_state
        #
        # Get the raw item state.
        #
        # The state of the item, including possibly {NULL} or {UNDEF}
        #
        # @return [State]
        #
        alias_method :raw_state, :state

        #
        # Check if the item has a state (not {UNDEF} or {NULL})
        #
        # @return [true, false]
        #
        def state?
          !raw_state.is_a?(Types::UnDefType)
        end

        # @!attribute [r] formatted_state
        #
        # Format the item's state according to its state description
        #
        # This may include running a transformation.
        #
        # @return [String]
        #
        # @example
        #   logger.info(Exterior_WindDirection.formatted_state) # => "NE (36°)"
        #
        def formatted_state
          # use to_string, not to_s, to get the original openHAB toString(), instead of any overrides
          # the JRuby library has defined
          raw_state_string = raw_state.to_string

          return raw_state_string unless (pattern = state_description&.pattern)

          transformed_state_string = org.openhab.core.transform.TransformationHelper.transform(OSGi.bundle_context,
                                                                                               pattern,
                                                                                               raw_state_string)
          return state.format(pattern) if transformed_state_string.nil? || transformed_state_string == raw_state_string

          transformed_state_string
        rescue org.openhab.core.transform.TransformationException
          raw_state_string
        end

        #
        # @!attribute [r] state
        # @return [State, nil]
        #   openHAB item state if state is not {UNDEF} or {NULL}, nil otherwise.
        #   This makes it easy to use with the
        #   [Ruby safe navigation operator `&.`](https://ruby-doc.org/core-2.6/doc/syntax/calling_methods_rdoc.html)
        #   Use {#undef?} or {#null?} to check for those states.
        #
        def state
          raw_state if state?
        end

        # @!method null?
        #   Check if the item state == {NULL}
        #   @return [true,false]

        # @!method undef?
        #   Check if the item state == {UNDEF}
        #   @return [true,false]

        #
        # Send a command to this item
        #
        # When this method is chained after the {OpenHAB::DSL::Items::Ensure::Ensurable#ensure ensure}
        # method, or issued inside an {OpenHAB::DSL.ensure_states ensure_states} block,
        # the command will only be sent if the item is not already in the same state.
        #
        # @param [Command] command command to send to the item
        # @return [self, nil] nil when `ensure` is in effect and the item was already in the same state,
        #   otherwise the item.
        #
        # @see DSL::Items::TimedCommand#command Timed Command
        # @see OpenHAB::DSL.ensure_states ensure_states
        # @see DSL::Items::Ensure::Ensurable#ensure ensure
        #
        def command(command)
          command = format_command(command)
          logger.trace "Sending Command #{command} to #{name}"
          $events.send_command(self, command)
          Proxy.new(self)
        end

        # not an alias to allow easier stubbing and overriding
        def <<(command)
          command(command)
        end

        # @!parse alias_method :<<, :command

        # @!method refresh
        #   Send the {REFRESH} command to the item
        #   @return [Item] `self`

        #
        # Send an update to this item
        #
        # @param [State] state
        # @return [self, nil] nil when `ensure` is in effect and the item was already in the same state,
        #   otherwise the item.
        #
        def update(state)
          state = format_update(state)
          logger.trace "Sending Update #{state} to #{name}"
          $events.post_update(self, state)
          Proxy.new(self)
        end

        # @!visibility private
        def format_command(command)
          command = format_type(command)
          return command if command.is_a?(Types::Command)

          command = command.to_s
          org.openhab.core.types.TypeParser.parse_command(getAcceptedCommandTypes, command) || command
        end

        # @!visibility private
        def format_update(state)
          state = format_type(state)
          return state if state.is_a?(Types::State)

          state = state.to_s
          org.openhab.core.types.TypeParser.parse_state(getAcceptedDataTypes, state) || StringType.new(state)
        end

        # formats a {Types::Type} to send to the event bus
        # @!visibility private
        def format_type(type)
          # actual Type types can be sent directly without conversion
          # make sure to use Type, because this method is used for both
          # #update and #command
          return type if type.is_a?(Types::Type)
          return NULL if type.nil?

          type.to_s
        end

        #
        # Defers notifying openHAB of modifications to multiple attributes until the block is complete.
        #
        # @param [true, false] force When true, allow modifications to file-based items.
        #   Normally a FrozenError is raised when attempting to modify file-based items, since
        #   they will then be out-of-sync with the definition on disk. Advanced users may do this
        #   knowingly and intentionally though, so an escape hatch is provided to allow runtime
        #   modifications.
        # @yield
        # @return [Object] the block's return value
        #
        # @example Modify label and tags for an item
        #   MySwitch.modify do
        #     MySwitch.label = "New Label"
        #     MySwitch.tags = :labeled
        #   end
        #
        def modify(force: false)
          raise ArgumentError, "you must pass a block to modify" unless block_given?
          return yield if instance_variable_defined?(:@modifying) && @modifying

          begin
            provider = self.provider
            if provider && !provider.is_a?(org.openhab.core.common.registry.ManagedProvider)
              raise FrozenError, "Cannot modify item #{name} from provider #{provider.inspect}." unless force

              provider = nil
              logger.debug("Forcing modifications to non-managed item #{name}")
            end
            @modified = false
            @modifying = true

            r = yield

            provider&.update(self) if @modified
            r
          ensure
            @modifying = false
          end
        end

        # @!attribute [rw] label
        # The item's descriptive label.
        # @return [String]
        def label=(value)
          modify do
            next if label == value

            @modified = true
            set_label(value)
          end
        end

        # @!attribute [rw] category
        # The item's category.
        # @return [String]
        def category=(value)
          modify do
            value = value&.to_s
            next if category == value

            @modified = true
            set_category(value)
          end
        end

        # @!attribute [rw] tags
        #   The item's tags
        #   @return [Array<String>]
        #   @overload tags
        #     Returns the item's tags.
        #     @return [Array<String>]
        #   @overload tags=(values)
        #     Sets the item's tags.
        #
        #     To remove all tags, assign an empty array or nil.
        #     @param [Array<String,Symbol,Semantics::Tag>] values Tags to set.
        #     @return [void]
        def tags=(values)
          modify do
            values = DSL::Items::ItemBuilder.normalize_tags(*values)
            next if values.to_set == tags.to_set

            @modified = true
            remove_all_tags
            add_tags(values)
          end
        end
      end
    end
  end
end

# @!parse GenericItem = OpenHAB::Core::Items::GenericItem
