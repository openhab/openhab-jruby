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

        # rubocop:disable Naming/MethodName -- these mimic Java fields, which are
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

        #
        # @!attribute [r] state
        # @return [State, nil]
        #   openHAB item state if state is not {UNDEF} or {NULL}, nil otherwise.
        #   This makes it easy to use with the
        #   [Ruby safe navigation operator `&.`](https://docs.ruby-lang.org/en/master/syntax/calling_methods_rdoc.html#label-Safe+Navigation+Operator)
        #   Use {#undef?} or {#null?} to check for those states.
        #
        # @see was
        #
        def state
          raw_state if state?
        end

        # @!method was_undef?
        #   Check if {#was} is {UNDEF}
        #   @return [true, false]

        # @!method was_null?
        #   Check if {#was} is {NULL}
        #   @return [true, false]

        #
        # Check if the item's previous state was not `nil`, {UNDEF} or {NULL}
        #
        # @return [true, false]
        #
        # @since openHAB 5.0
        #
        def was?
          !last_state.nil? && !last_state.is_a?(Types::UnDefType)
        end

        #
        # @!attribute [r] was
        #
        # @return [State] The previous state of the item. nil if the item was never updated, or
        #   if the item was updated to {NULL} or {UNDEF}.
        # @since openHAB 5.0
        #
        # @see state
        # @see Item#last_state
        #
        def was
          last_state if was?
        end

        # @!method null?
        #   Check if the item state == {NULL}
        #   @return [true,false]

        # @!method undef?
        #   Check if the item state == {UNDEF}
        #   @return [true,false]

        #
        # @method time_series=(time_series)
        #   Set a new time series.
        #
        #   This will trigger a {DSL::Rules::BuilderDSL#time_series_updated time_series_updated} event.
        #
        #   @param [Core::Types::TimeSeries] time_series New time series to set.
        #   @return [void]
        #
        #   @since openHAB 4.1
        #

        #
        # Defers notifying openHAB of modifications to multiple attributes until the block is complete.
        #
        # @param [true, false] force When true, allow modifications to file-based items.
        #   Normally a FrozenError is raised when attempting to modify file-based items, since
        #   they will then be out-of-sync with the definition on disk. Advanced users may do this
        #   knowingly and intentionally though, so an escape hatch is provided to allow runtime
        #   modifications.
        # @yield
        # @yieldparam [Item] self The item
        # @return [Object] the block's return value
        #
        # @example Modify label and tags for an item
        #   MySwitch.modify do
        #     MySwitch.label = "New Label"
        #     MySwitch.tags = :labeled
        #   end
        #
        # @example Using the block argument to access the item
        #   MySwitch.modify do |item|
        #     item.label = "New Label"
        #     item.icon = :switch
        #     item.tags = Semantics::Switch, Semantics::Light
        #   end
        #
        def modify(force: false)
          raise ArgumentError, "you must pass a block to modify" unless block_given?

          proxied_self = Proxy.new(self)

          return yield(proxied_self) if instance_variable_defined?(:@modifying) && @modifying

          begin
            provider = self.provider
            if provider && !provider.is_a?(org.openhab.core.common.registry.ManagedProvider)
              raise FrozenError, "Cannot modify item #{name} from provider #{provider.inspect}." unless force

              provider = nil
              logger.debug { "Forcing modifications to non-managed item #{name}" }
            end
            @modified = false
            @modifying = true

            r = yield(proxied_self)

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
        # The item's category (icon).
        # @return [String]
        def category=(value)
          modify do
            value = value&.to_s
            next if category == value

            @modified = true
            set_category(value)
          end
        end
        alias_method :icon, :category
        alias_method :icon=, :category=

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
            values = DSL::Items::Tags.normalize(*values)
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
