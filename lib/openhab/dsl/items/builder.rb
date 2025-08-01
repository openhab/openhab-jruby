# frozen_string_literal: true

module OpenHAB
  module DSL
    #
    # Contains extensions to simplify working with {Item Items}.
    #
    module Items
      # An item builder allows you to dynamically create openHAB items at runtime.
      # This can be useful either to create items as soon as the script loads,
      # or even later based on a rule executing.
      #
      # @example Create/update JRuby-provided items at runtime
      #   items.build do
      #     switch_item MySwitch, "My Switch"
      #     switch_item NotAutoupdating, autoupdate: false, channel: "mqtt:topic:1#light"
      #     group_item MyGroup do
      #       contact_item ItemInGroup, channel: "binding:thing#channel"
      #     end
      #     # passing `thing` to a group item will automatically use it as the base
      #     # for item channels
      #     group_item Equipment, tags: Semantics::HVAC, thing: "binding:thing"
      #       string_item Mode, tags: Semantics::Control, channel: "mode"
      #     end
      #
      #     # dimension Temperature inferred
      #     number_item OutdoorTemp, format: "%.1f %unit%", unit: "°F"
      #
      #     # unit lx, dimension Illuminance, format "%s %unit%" inferred
      #     number_item OutdoorBrightness, state: 10_000 | "lx"
      #   end
      #
      # @example Create/update persistent managed-items that are stored in the JSONDB and are editable in the MainUI
      #   items.build(:persistent) do
      #     switch_item MySwitch, "My Switch"
      #   end
      #
      # @see OpenHAB::Core::Items::Registry#build items.build for the arguments to this method
      #
      module Builder
        include Core::EntityLookup

        self.create_dummy_items = true

        class << self
          private

          # @!macro def_item_method
          #   @!method $1_item(name, label = nil, **kwargs)
          #   Create a new $1 item
          #   @param name [String, Symbol, Core::Items::Proxy] The name for the new item.
          #     Note that you can use a string, a symbol, or even a literal constant name
          #   @param label [String] The item label
          #   @yieldparam [ItemBuilder] builder Item for further customization
          #   @see ItemBuilder#initialize ItemBuilder#initialize for additional arguments.
          def def_item_method(method)
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{method}_item(*args, **kwargs, &block)         # def dimmer_item(*args, **kwargs, &block)
                item(#{method.inspect}, *args, **kwargs, &block)  #   item(:dimmer, *args, **kwargs, &block)
              end                                                 # end
            RUBY
          end
        end

        # @return [CallItem]
        def_item_method(:call)
        # @return [ColorItem]
        def_item_method(:color)
        # @return [ContactItem]
        def_item_method(:contact)
        # @return [DateTimeItem]
        def_item_method(:date_time)
        # @return [DimmerItem]
        def_item_method(:dimmer)
        # @return [ImageItem]
        def_item_method(:image)
        # @return [LocationItem]
        def_item_method(:location)
        # @return [NumberItem]
        def_item_method(:number)
        # @return [PlayerItem]
        def_item_method(:player)
        # @return [RollershutterItem]
        def_item_method(:rollershutter)
        # @return [StringItem]
        def_item_method(:string)
        # @return [SwitchItem]
        def_item_method(:switch)

        # Create a new {GroupItem}
        #
        # @!method group_item(name, label = nil, **kwargs)
        # @param name [String] The name for the new item
        # @param label [String] The item label
        # @param (see GroupItemBuilder#initialize)
        # @yieldparam [GroupItemBuilder] builder Item for further customization
        # @return [GroupItem]
        def group_item(*args, **kwargs, &block)
          item = GroupItemBuilder.new(*args, provider:, **kwargs)
          item.instance_eval(&block) if block
          result = provider.add(item)
          item.members.each do |i|
            provider.add(i)
          end
          result
        end

        private

        def item(*args, **kwargs, &block)
          item = ItemBuilder.new(*args, provider:, **kwargs)
          item.instance_eval(&block) if block
          r = provider.add(item)
          return Core::Items::Proxy.new(r) if r.is_a?(Item)

          item
        end
      end

      # @!visibility private
      class BaseBuilderDSL
        include Builder

        # @!visibility private
        class ProviderWrapper
          attr_reader :provider

          def initialize(provider, update:)
            @provider = provider
            @update = update
          end

          # @!visibility private
          def add(builder)
            if DSL.items.key?(builder.name)
              raise ArgumentError, "Item #{builder.name} already exists" unless @update

              # Use provider.get because openHAB's ManagedProvider does not support the #[] method.
              unless (old_item = provider.get(builder.name))
                raise FrozenError, "Item #{builder.name} is managed by #{DSL.items[builder.name].provider}"
              end

              item = builder.build
              if item.config_eql?(old_item)
                logger.debug { "Not replacing existing item #{item.uid} because it is identical" }
                item = old_item
              else
                logger.debug { "Replacing existing item #{item.uid} because it is not identical" }
                provider.update(item)
              end
              item.metadata.merge!(builder.metadata)
              item.metadata
                  .reject { |namespace, _| builder.metadata.key?(namespace) }
                  .each do |namespace, metadata|
                item.metadata.delete(namespace) if metadata.provider == Core::Items::Metadata::Provider.current
              end
            else
              item = builder.build
              item.metadata.merge!(builder.metadata)
              provider.add(item)
            end

            item.update(builder.state) unless builder.state.nil?

            # make sure to add the item to the registry before linking it
            channel_uids = builder.channels.to_set do |(channel, config)|
              channel = channel.to_s
              # fill in partial channel names from item's or group's thing id
              if !channel.include?(":") &&
                 (thing = builder.thing ||
                  thing = builder.groups.find { |g| g.is_a?(GroupItemBuilder) && g.thing }&.thing)
                channel = "#{thing}:#{channel}"
              end

              item.link(channel, config).linked_uid
            end

            # remove links not in the new item
            provider = Core::Things::Links::Provider.current
            provider.all.each do |link|
              provider.remove(link.uid) if link.item_name == item.name && !channel_uids.include?(link.linked_uid)
            end
            item
          end
        end
        private_constant :ProviderWrapper

        # @return [org.openhab.core.items.ItemProvider]
        attr_reader :provider

        def initialize(provider, update:)
          @provider = ProviderWrapper.new(Core::Items::Provider.current(provider), update:)
        end
      end

      # The ItemBuilder DSL allows you to customize an Item
      class ItemBuilder
        include Core::EntityLookup

        # The type of this item
        # @example
        #   type #=> :switch
        # @return [Symbol]
        attr_reader :type
        # Item name
        # @return [String]
        attr_accessor :name
        # Item label
        # @return [String, nil]
        attr_accessor :label
        # Unit dimension (for number items only)
        #
        # If {unit} is provided, and {dimension} is not, it will be inferred.
        #
        # @return [String, nil]
        attr_accessor :dimension
        # Unit (for number items only)
        #
        # @return [String, nil]
        attr_reader :unit
        # The formatting pattern for the item's state
        #
        # If {unit} is provided, and {format} is not, it will be inferred.
        #
        # @return [String, nil]
        attr_accessor :format
        # The valid range for a number item
        # @return [Range, nil]
        attr_accessor :range
        # The step size for a number item
        # @return [Number, nil]
        attr_accessor :step
        # If the item is read-only, and does not accept commands
        # @return [true, false, nil]
        attr_accessor :read_only
        alias_method :read_only?, :read_only
        # A list of valid commands
        # If a hash, keys are commands, and values are labels
        # @return [Hash, Array, nil]
        attr_accessor :command_options
        # A list of valid states
        # If a hash, keys are commands, and values are labels
        # @return [Hash, Array, nil]
        attr_accessor :state_options
        # The icon to be associated with the item
        # @return [Symbol, String, nil]
        attr_accessor :icon
        # Autoupdate setting
        # @return [true, false, nil]
        attr_accessor :autoupdate
        # @return [String, Core::Things::Thing, Core::Things::ThingUID, nil]
        #   {Core::Things::ThingUID Thing} from which to resolve relative channel ids
        attr_accessor :thing
        # @return [Core::Items::Metadata::NamespaceHash]
        attr_reader :metadata
        # Initial state
        #
        # If {state} is set to a {QuantityType}, and {unit} is not set, it will be inferred.
        #
        # @return [Core::Types::State]
        attr_reader :state

        attr_writer :channels, :groups, :tags

        # @!attribute [rw] channels
        # @return [Array<String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, Array>]
        #   {Core::Things::ChannelUID Channel} to link the item to

        # @!attribute [rw] groups
        # @return [Array<String, GroupItem>] Groups to which this item should be added

        # @!attribute [rw] tags
        # @return [Array<String>] Tags to apply to this item

        # This comment needs to exist otherwise YARD thinks the above attribute should apply to the metaclass
        class << self
          # @!visibility private
          def item_factory
            @item_factory ||= OpenHAB::OSGi.service("org.openhab.core.items.ItemFactory")
          end
        end

        # @param dimension [Symbol, String, nil] The unit dimension for a {NumberItem} (see {ItemBuilder#dimension})
        #   Note the dimension must be properly capitalized.
        # @param unit [Symbol, String, nil] The unit for a {NumberItem} (see {ItemBuilder#unit})
        # @param format [String, nil] The formatting pattern for the item's state (see {ItemBuilder#format})
        # @param icon [Symbol, String, nil] The icon to be associated with the item (see {ItemBuilder#icon})
        # @param group [String,
        #   GroupItem,
        #   GroupItemBuilder,
        #   Array<String, GroupItem, GroupItemBuilder>,
        #   nil]
        #        Group(s) to which this item should be added (see {ItemBuilder#group}).
        # @param groups [String,
        #   GroupItem,
        #   GroupItemBuilder,
        #   Array<String, GroupItem, GroupItemBuilder>,
        #   nil]
        #        Fluent alias for `group`.
        # @param tag [String, Symbol, Semantics::Tag, Array<String, Symbol, Semantics::Tag>, nil]
        #        Tag(s) to apply to this item (see {ItemBuilder#tag}).
        # @param tags [String, Symbol, Semantics::Tag, Array<String, Symbol, Semantics::Tag>, nil]
        #        Fluent alias for `tag`.
        # @param autoupdate [true, false, nil] Autoupdate setting (see {ItemBuilder#autoupdate})
        # @param thing [String, Core::Things::Thing, Core::Things::ThingUID, nil]
        #   A Thing to be used as the base for the channel.
        # @param channel [String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, nil]
        #   Channel to link the item to (see {ItemBuilder#channel}).
        # @param expire [String] An expiration specification (see {ItemBuilder#expire}).
        # @param alexa [String, Symbol, Array<(String, Hash<String, Object>)>, nil]
        #   Alexa metadata (see {ItemBuilder#alexa})
        # @param ga [String, Symbol, Array<(String, Hash<String, Object>)>, nil]
        #   Google Assistant metadata (see {ItemBuilder#ga})
        # @param homekit [String, Symbol, Array<(String, Hash<String, Object>)>, nil]
        #   Homekit metadata (see {ItemBuilder#homekit})
        # @param matter [String, Symbol, Array<(String, Hash<String, Object>)>, nil]
        #   Matter metadata (see {ItemBuilder#matter})
        # @param metadata [Hash<String, Hash>] Generic metadata (see {ItemBuilder#metadata})
        # @param state [State] Initial state
        def initialize(type,
                       name = nil,
                       label = nil,
                       provider:,
                       dimension: nil,
                       unit: nil,
                       format: nil,
                       range: nil,
                       step: nil,
                       read_only: nil,
                       command_options: nil,
                       state_options: nil,
                       icon: nil,
                       group: nil,
                       groups: nil,
                       tag: nil,
                       tags: nil,
                       autoupdate: nil,
                       thing: nil,
                       channel: nil,
                       channels: nil,
                       expire: nil,
                       alexa: nil,
                       ga: nil, # rubocop:disable Naming/MethodParameterName
                       homekit: nil,
                       matter: nil,
                       metadata: nil,
                       state: nil)
          raise ArgumentError, "`name` cannot be nil" if name.nil?

          if dimension
            raise ArgumentError, "`dimension` can only be specified with NumberItem" unless type == :number

            begin
              org.openhab.core.types.util.UnitUtils.parse_dimension(dimension.to_s)
            rescue java.lang.IllegalArgumentException
              raise ArgumentError, "Invalid dimension '#{dimension}'"
            end
          end

          name = name.name if name.respond_to?(:name)
          if provider.is_a?(GroupItemBuilder)
            name = "#{provider.name_base}#{name}"
            label = "#{provider.label_base}#{label}".strip if label
          end
          @provider = provider
          @type = type
          @name = name.to_s
          @label = label
          @dimension = dimension
          @format = format
          @range = range
          @step = step
          @read_only = read_only
          @command_options = command_options
          @state_options = state_options
          self.unit = unit
          @icon = icon
          @groups = []
          @tags = []
          @metadata = Core::Items::Metadata::NamespaceHash.new
          @metadata.merge!(metadata) if metadata
          @autoupdate = autoupdate
          @channels = []
          @thing = thing
          @expire = nil
          if expire
            expire = Array(expire)
            expire_config = expire.pop if expire.last.is_a?(Hash)
            expire_config ||= {}
            self.expire(*expire, **expire_config)
          end
          self.alexa(alexa) if alexa
          self.ga(ga) if ga
          self.homekit(homekit) if homekit
          self.matter(matter) if matter
          self.state = state

          self.group(*group)
          self.groups(*groups)

          self.tag(*tag)
          self.tags(*tags)

          self.channel(*channel)
          self.channels(*channels)
        end

        #
        # The item's label if one is defined, otherwise its name.
        #
        # @return [String]
        #
        def to_s
          label || name
        end

        #
        # Tag item
        #
        # @return [Array<String>]
        #
        # @overload tag(tag)
        #   @param tag [String, Symbol, Semantics::Tag]
        #   @return [Array<String>]
        #
        # @overload tags
        #   @return [Array<String>]
        #
        # @overload tags(*tags)
        #   @param tags [String, Symbol, Semantics::Tag]
        #   @return [Array<String>]
        #
        def tag(*tags)
          return @tags if tags.empty?

          @tags.concat(Tags.normalize(*tags))
        end
        alias_method :tags, :tag

        #
        # Add this item to a group
        #
        # @return [Array<String, GroupItemBulder, GroupItem>]
        #
        # @overload group(group)
        #   @param group [String, GroupItemBuilder, GroupItem]
        #   @return [Array<String, GroupItemBulder, GroupItem>]
        #
        # @overload groups
        #   @return [Array<String, GroupItemBulder, GroupItem>]
        #
        # @overload groups(*groups)
        #   @param groups [String, GroupItemBuilder, GroupItem]
        #   @return [Array<String, GroupItemBulder, GroupItem>]
        #
        def group(*groups)
          return @groups if groups.empty?

          unless groups.all? do |group|
                   group.is_a?(String) || group.is_a?(Core::Items::GroupItem) || group.is_a?(GroupItemBuilder)
                 end
            raise ArgumentError, "`group` must be a `GroupItem`, `GroupItemBuilder`, or a `String`"
          end

          @groups.concat(groups)
        end
        alias_method :groups, :group

        #
        # @!method alexa(value, config = nil)
        #   Shortcut for adding Alexa metadata
        #
        #   @see https://www.openhab.org/docs/ecosystem/alexa/
        #
        #   @param value [String, Symbol] Type of Alexa endpoint
        #   @param config [Hash, nil] Additional Alexa configuration
        #   @return [void]
        #

        #
        # @!method ga(value, config = nil)
        #   Shortcut for adding Google Assistant metadata
        #
        #   @see https://www.openhab.org/docs/ecosystem/google-assistant/
        #
        #   @param value [String, Symbol] Type of Google Assistant endpoint
        #   @param config [Hash, nil] Additional Google Assistant configuration
        #   @return [void]
        #

        #
        # @!method homekit(value, config = nil)
        #   Shortcut for adding Homekit metadata
        #
        #   @see https://www.openhab.org/addons/integrations/homekit/
        #
        #   @param value [String, Symbol] Type of Homekit accessory or characteristic
        #   @param config [Hash, nil] Additional Homekit configuration
        #   @return [void]
        #

        #
        # @!method matter(value, config = nil)
        #   Shortcut for adding Matter metadata
        #
        #   @see https://www.openhab.org/addons/bindings/matter/#matter-bridge
        #
        #   @param value [String, Symbol] Matter device type or attribute(s)
        #   @param config [Hash, nil] Additional Matter configuration
        #   @return [void]
        #

        %i[alexa ga homekit matter].each do |shortcut|
          define_method(shortcut) do |value = nil, config = nil|
            value, config = value if value.is_a?(Array)
            metadata[shortcut] = [value, config]
          end
        end

        #
        # Add a channel link to this item.
        #
        # @return [Array<String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, Array>]
        #
        # @overload channel(channel, config = {})
        #   @param channel [String, Symbol, Core::Things::ChannelUID, Core::Things::Channel]
        #     Channel to link the item to. When {thing} is set, this can be a relative channel name.
        #   @param config [Hash] Additional configuration, such as profile
        #   @return [Array<String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, Array>]
        #
        # @overload channels
        #   @return [Array<String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, Array>]
        #
        # @overload channels(*channels)
        #   @param channels [String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, Array]
        #     Channels to link the item to. When {thing} is set, these can be relative channel names.
        #     Each array element can also be a two element array with the first element being the
        #     channel, and the second element being a config hash.
        #   @return [Array<String, Symbol, Core::Things::ChannelUID, Core::Things::Channel, Array>]
        #
        # @example
        #   items.build do
        #     date_time_item Bedroom_Light_Updated do
        #       channel "hue:0210:1:bulb1:color", profile: "system:timestamp-update"
        #     end
        #   end
        #
        # @example Relative channel name
        #   items.build do
        #     switch_item Bedroom_Light, thing: "mqtt:topic:bedroom-light", channel: :power
        #   end
        #
        # @example Multiple channels
        #   items.build do
        #     dimmer_item DemoDimmer, channels: ["hue:0210:bridge:1:color", "knx:device:bridge:generic:controlDimmer"]
        #   end
        #
        # @example Multiple channels in a block
        #   items.build do
        #     dimmer_item DemoDimmer do
        #       channel "hue:0210:bridge:1:color"
        #       channel "knx:device:bridge:generic:controlDimmer"
        #     end
        #   end
        #
        # @example Multiple channels with config
        #   items.build do
        #     dimmer_item DemoDimmer, channels: [["hue:0210:bridge:1:color", profile: "system:follow"],
        #                                        "knx:device:bridge:generic:controlDimmer"]
        #   end
        #
        def channel(*channels)
          return @channels if channels.empty?

          channels = [channels] if channels.length == 2 && channels[1].is_a?(Hash)

          channels.each do |channel|
            orig_channel = channel
            channel = channel.first if channel.is_a?(Array)
            next if channel.is_a?(String) ||
                    channel.is_a?(Symbol) ||
                    channel.is_a?(Core::Things::ChannelUID) ||
                    channel.is_a?(Core::Things::Channel)

            raise ArgumentError, "channel #{orig_channel.inspect} must be a `String`, `Symbol`, `ChannelUID`, or " \
                                 "`Channel`, or a two element array with the first element those types, and the " \
                                 "second element a Hash"
          end

          @channels.concat(channels)
        end
        alias_method :channels, :channel

        #
        # @!method expire(duration, command: nil, state: nil, ignore_state_updates: nil, ignore_commands: nil)
        #
        # Configure item expiration
        #
        # @param duration [String, Duration, nil] Duration after which the command or state should be applied
        # @param command [String, nil] Command to send on expiration
        # @param state [String, nil] State to set on expiration
        # @param ignore_state_updates [true, false] When true, state updates will not reset the expire timer
        # @param ignore_commands [true, false] When true, commands will not reset the expire timer
        # @return [void]
        #
        # @example Get the current expire setting
        #   expire
        # @example Clear any expire setting
        #   expire nil
        # @example Use a duration
        #   expire 5.hours
        # @example Use a string duration
        #   expire "5h"
        # @example Set a specific state on expiration
        #   expire 5.minutes, NULL
        #   expire 5.minutes, state: NULL
        # @example Send a command on expiration
        #   expire 5.minutes, command: OFF
        # @example Specify the duration and command in the same string
        #   expire "5h,command=OFF"
        # @example Set the expire configuration
        #   expire 5.minutes, ignore_state_updates: true
        #
        def expire(*args, command: nil, state: nil, ignore_state_updates: nil, ignore_commands: nil)
          unless (0..2).cover?(args.length)
            raise ArgumentError,
                  "wrong number of arguments (given #{args.length}, expected 0..2)"
          end
          return @expire if args.empty?

          state = args.last if args.length == 2
          raise ArgumentError, "cannot provide both command and state" if command && state

          duration = args.first
          return @expire = nil if duration.nil?

          duration = duration.to_s[2..].downcase if duration.is_a?(Duration)
          state = "'#{state}'" if state.respond_to?(:to_str) && type == :string

          value = duration
          value += ",state=#{state}" if state
          value += ",command=#{command}" if command

          config = { ignoreStateUpdates: ignore_state_updates, ignoreCommands: ignore_commands }
          config.compact!
          @expire = [value, config]
        end

        # @!attribute [w] unit
        #
        # Unit (for number items only).
        #
        # If dimension or format are not yet set, they will be inferred.
        #
        # @return [String, nil]
        def unit=(unit)
          @unit = unit

          if (openhab_unit = unit && org.openhab.core.types.util.UnitUtils.parse_unit(unit))
            self.dimension ||= "Temperature" if openhab_unit == Units::MIRED
            self.dimension ||= org.openhab.core.types.util.UnitUtils.get_dimension_name(openhab_unit)
          end
          self.format ||= unit && (if Gem::Version.new(Core::VERSION) >= Gem::Version.new("4.0.0.M3")
                                     "%s %unit%"
                                   else
                                     "%s #{unit.gsub("%", "%%")}"
                                   end)
        end

        # @!attribute [w] state
        #
        # Initial state
        #
        # If {state} is set to a {QuantityType}, and {unit} is not set, it will be inferred.
        #
        # @return [Core::Types::State]
        def state=(state)
          @state = state

          self.unit ||= state.unit.to_s if state.is_a?(QuantityType)
        end

        # @!visibility private
        def build
          item = create_item
          item.set_label(label) # Don't use item#label= because it triggers a provider.update
          item.set_category(icon.to_s) if icon # ditto here
          groups.each do |group|
            group = group.name if group.respond_to?(:name)
            item.add_group_name(group.to_s)
          end
          tags.each do |tag|
            item.add_tag(tag)
          end
          metadata["autoupdate"] = autoupdate.to_s unless autoupdate.nil?
          metadata["expire"] = expire if expire
          if format || range || step || !read_only.nil? || state_options
            sd = {}
            sd["pattern"] = format if format
            sd["min"] = range.begin&.to_d if range&.begin
            sd["max"] = range.end&.to_d if range&.end
            sd["step"] = step if step
            sd["readOnly"] = read_only unless read_only.nil?
            if state_options
              sd["options"] = if state_options.respond_to?(:to_hash)
                                state_options.to_hash.map { |k, v| "#{k}=#{v}" }.join(",")
                              elsif state_options.respond_to?(:to_ary)
                                state_options.to_ary.join(",")
                              else
                                state_options.to_s
                              end
            end

            metadata["stateDescription"] = sd
          end
          if command_options
            options = if command_options.respond_to?(:to_hash)
                        command_options.to_hash.map { |k, v| "#{k}=#{v}" }.join(",")
                      elsif command_options.respond_to?(:to_ary)
                        command_options.to_ary.join(",")
                      else
                        command_options.to_s
                      end
            metadata["commandDescription"] = { "options" => options }
          end
          metadata["unit"] = unit if unit
          item
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Items::#{inspect_type}ItemBuilder#{type_details} #{name} #{label.inspect}"
          s += " category=#{icon.inspect}" if icon
          s += " tags=#{tags.inspect}" unless tags.empty?
          s += " groups=#{groups.map { |g| g.respond_to?(:name) ? g.name : g }.inspect}" unless groups.empty?
          s += " metadata=#{metadata.to_h.inspect}" unless metadata.empty?
          "#{s}>"
        end

        private

        # @return [String]
        def inspect_type
          type.to_s.capitalize
        end

        # @return [String, nil]
        def type_details
          ":#{dimension}" if dimension
        end

        def create_item
          type = @type.to_s.gsub(/(?:^|_)[a-z]/) { |match| match[-1].upcase }
          type = "#{type}:#{dimension}" if dimension
          self.class.item_factory.create_item(type, name)
        end
      end

      # Allows customizing a group. You can also call any method from {Builder}, and those
      # items will automatically be a member of this group.
      class GroupItemBuilder < ItemBuilder
        include Builder

        # This has to be duplicated here, since {Builder} includes DSL, so DSL#unit
        # will be seen first, but we really want ItemBuilder#unit

        # (see ItemBuilder#unit)
        attr_reader :unit

        Builder.public_instance_methods.each do |m|
          next unless Builder.instance_method(m).owner == Builder

          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{m}(*args, groups: nil, **kwargs)  # def dimmer_item(*args, groups: nil, **kwargs)
              groups = Array.wrap(groups)           #   groups = Array.wrap(groups)
              groups << self                        #   groups << self
              super                                 #   super
            end                                     # end
          RUBY
        end

        FUNCTION_REGEX = /^([a-z]+)(?:\((.*)\))?/i
        private_constant :FUNCTION_REGEX

        # The combiner function for this group
        # @return [String, nil]
        attr_accessor :function
        # A thing to be used as the base for the channel of any member items
        # @return [Core::Things::ThingUID, Core::Things::Thing, String, nil]
        attr_accessor :thing
        # A prefix to be added to the name of any member items
        # @return [String, nil]
        attr_accessor :name_base
        # A prefix to be added to the label of any member items
        # @return [String, nil]
        attr_accessor :label_base
        # Members to be created in this group
        # @return [Array<ItemBuilder>]
        attr_reader :members

        # @param type [Symbol, nil] The base type for the group
        # @param function [String, nil] The combiner function for this group
        # @param thing [Core::Things::ThingUID, Core::Things::Thing, String, nil]
        #        A Thing to be used as the base for the channel for any contained items.
        # @param (see ItemBuilder#initialize)
        def initialize(*args, type: nil, function: nil, thing: nil, **kwargs)
          raise ArgumentError, "invalid function #{function}" if function && !function.match?(FUNCTION_REGEX)

          super(type, *args, **kwargs)
          @function = function
          @members = []
          @thing = thing
        end

        # @!visibility private
        def create_item
          base_item = super if type
          if function
            require "csv"

            match = function.match(FUNCTION_REGEX)

            dto = org.openhab.core.items.dto.GroupFunctionDTO.new
            dto.name = match[1]
            dto.params = CSV.parse_line(match[2]) if match[2]
            function = org.openhab.core.items.dto.ItemDTOMapper.map_function(base_item, dto)
            Core::Items::GroupItem.new(name, base_item, function)
          else
            Core::Items::GroupItem.new(name, base_item)
          end
        end

        # @!visibility private
        def add(child_item)
          @members << child_item
        end

        private

        # @return [String]
        def inspect_type
          "Group"
        end

        # @return [String, nil]
        def type_details
          r = super
          r = "#{r}:#{function}" if function
          r
        end

        def provider
          self
        end
      end
    end
  end
end
