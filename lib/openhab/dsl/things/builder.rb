# frozen_string_literal: true

module OpenHAB
  module DSL
    #
    # Contains extensions to simplify working with {Core::Things::Thing Thing}s.
    #
    module Things
      # A thing builder allows you to dynamically create openHAB things at runtime.
      # This can be useful either to create things as soon as the script loads,
      # or even later based on a rule executing.
      #
      # @example Create a Thing from the Astro Binding
      #   things.build do
      #     thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      #   end
      #
      # @example Create a Thing with Channels
      #   thing_config = {
      #     availabilityTopic: "my-switch/status",
      #     payloadAvailable: "online",
      #     payloadNotAvailable: "offline"
      #   }
      #   things.build do
      #     thing("mqtt:topic:my-switch", "My Switch", bridge: "mqtt:broker:mosquitto", config: thing_config) do
      #       channel("switch1", "switch", config: {
      #         stateTopic: "stat/my-switch/switch1/state", commandTopic: "cmnd/my-switch/switch1/command"
      #       })
      #       channel("button1", "string", config: {
      #         stateTopic: "stat/my-switch/button1/state", commandTopic: "cmnd/my-switch/button1/command"
      #       })
      #     end
      #   end
      #
      # @see ThingBuilder#initialize ThingBuilder#initialize for #thing's parameters
      # @see ChannelBuilder#initialize ChannelBuilder#initialize for #channel's parameters
      # @see Items::Builder
      #
      class Builder
        # @return [org.openhab.core.thing.ManagedThingProvider]
        attr_reader :provider

        def initialize(provider)
          @provider = Core::Things::Provider.current(provider)
        end

        # Create a new Bridge
        # @see BridgeBuilder#initialize
        def bridge(*args, **kwargs, &block)
          build(BridgeBuilder, *args, **kwargs, &block)
        end

        # Create a new Thing
        # @see ThingBuilder#initialize
        def thing(*args, **kwargs, &block)
          build(ThingBuilder, *args, **kwargs, &block)
        end

        private

        def build(klass, *args, **kwargs, &block)
          builder = klass.new(*args, **kwargs)
          builder.instance_eval(&block) if block
          thing = provider.add(builder.build)
          thing = Core::Things::Proxy.new(thing)
          thing.enable(enabled: builder.enabled) unless builder.enabled.nil?
          thing
        end
      end

      # The ThingBuilder DSL allows you to customize a thing
      class ThingBuilder
        # The label for this thing
        # @return [String, nil]
        attr_accessor :label
        # The location for this thing
        # @return [String, nil]
        attr_accessor :location
        # The id for this thing
        # @return [Core::Things::ThingUID]
        attr_reader :uid
        # The type of this thing
        # @return [ThingTypeUID]
        attr_reader :thing_type_uid
        # The bridge of this thing
        # @return [Core::Things::ThingUID, nil]
        attr_reader :bridge_uid
        # The config for this thing
        # @return [Hash, nil]
        attr_reader :config
        # If the thing should be enabled after it is created
        # @return [true, false, nil]
        attr_reader :enabled
        # Explicitly configured channels on this thing
        # @return [Array<ChannelBuilder>]
        attr_reader :channels

        class << self
          # @!visibility private
          def thing_type_registry
            @thing_type_registry ||= OSGi.service("org.openhab.core.thing.type.ThingTypeRegistry")
          end

          # @!visibility private
          def config_description_registry
            @config_description_registry ||=
              OSGi.service("org.openhab.core.config.core.ConfigDescriptionRegistry")
          end

          # @!visibility private
          def thing_factory_helper
            @thing_factory_helper ||= begin
              # this is an internal class, so OSGi doesn't put it on the main class path,
              # so we have to go find it ourselves manually
              bundle = org.osgi.framework.FrameworkUtil.get_bundle(org.openhab.core.thing.Thing.java_class)
              bundle.load_class("org.openhab.core.thing.internal.ThingFactoryHelper").ruby_class
            end
          end
        end

        #
        # Constructor for ThingBuilder
        #
        # @param [String] uid The ThingUID for the created Thing.
        #   This can consist one or more segments separated by a colon. When the uid contains:
        #   - One segment: When the uid contains one segment, `binding` or `bridge` id must be provided.
        #   - Two segments: `typeid:thingid` The `binding` or `bridge` id must be provided.
        #   - Three or more segments: `bindingid:typeid:[bridgeid...]:thingid`. The `type` and `bridge` can be omitted
        # @param [String] label The Thing's label.
        # @param [String] binding The binding id. When this argument is not provided,
        #   the binding id must be deducible from the `uid`, `type`, or `bridge`.
        # @param [String] type The type id. When this argument is not provided,
        #   it will be deducible from the `uid` if it contains two or more segments.
        #   To create a Thing with a blank type id, use one segment for `uid` and provide the binding id.
        # @param [String, BridgeBuilder] bridge The bridge uid, if the Thing should belong to a bridge.
        # @param [String, Item] location The location of this Thing.
        #   When given an Item, use the item's label as the location.
        # @param [Hash] config The Thing's configuration, as required by the binding. The key can be strings or symbols.
        # @param [true,false] enabled Whether the Thing should be enabled or disabled.
        #
        def initialize(uid, label = nil, binding: nil, type: nil, bridge: nil, location: nil, config: {}, enabled: nil)
          @channels = []
          uid = uid.to_s
          uid_segments = uid.split(org.openhab.core.common.AbstractUID::SEPARATOR)
          @bridge_uid = nil
          bridge = bridge.uid if bridge.is_a?(org.openhab.core.thing.Bridge) || bridge.is_a?(BridgeBuilder)
          bridge = bridge&.to_s
          bridge_segments = bridge&.split(org.openhab.core.common.AbstractUID::SEPARATOR) || []
          type = type&.to_s

          # infer missing components
          type ||= uid_segments[0] if uid_segments.length == 2
          type ||= uid_segments[1] if uid_segments.length > 2
          binding ||= uid_segments[0] if uid_segments.length > 2
          binding ||= bridge_segments[0] if bridge_segments && bridge_segments.length > 2

          if bridge
            bridge_segments.unshift(binding) if bridge_segments.length < 3
            @bridge_uid = org.openhab.core.thing.ThingUID.new(*bridge_segments)
          end

          thinguid = if uid_segments.length > 2
                       [binding, type, uid_segments.last].compact
                     else
                       [binding, type, @bridge_uid&.id, uid_segments.last].compact
                     end

          @uid = org.openhab.core.thing.ThingUID.new(*thinguid)
          @thing_type_uid = org.openhab.core.thing.ThingTypeUID.new(*@uid.all_segments[0..1])
          @label = label
          @location = location
          @location = location.label if location.is_a?(Item)
          @config = config.transform_keys(&:to_s)
          @enabled = enabled
        end

        # Add an explicitly configured channel to this item
        # @see ChannelBuilder#initialize
        # @return [Core::Things::Channel]
        def channel(*args, **kwargs, &block)
          channel = ChannelBuilder.new(*args, thing: self, **kwargs)
          channel.instance_eval(&block) if block
          channel.build.tap { |c| @channels << c }
        end

        # @!visibility private
        def build
          configuration = Core::Configuration.new(config)
          if thing_type
            self.class.thing_factory_helper.apply_default_configuration(
              configuration,
              thing_type,
              self.class.config_description_registry
            )
          end
          builder = org.openhab.core.thing.binding.builder.ThingBuilder
                       .create(thing_type_uid, uid)
                       .with_label(label)
                       .with_configuration(configuration)
                       .with_bridge(bridge_uid)
                       .with_channels(channels)

          if thing_type
            # can't use with_channels, or it will wipe out custom channels from above
            self.class.thing_factory_helper.create_channels(thing_type,
                                                            uid,
                                                            self.class.config_description_registry).each do |channel|
              builder.with_channel(channel)
            end
            builder.with_properties(thing_type.properties)
          end

          thing = builder.build
          Core::Things.manager.set_enabled(uid, enabled) unless enabled.nil?
          thing
        end

        private

        def thing_type
          @thing_type ||= self.class.thing_type_registry.get_thing_type(thing_type_uid)
        end
      end

      # The BridgeBuilder DSL allows you to customize a thing
      class BridgeBuilder < ThingBuilder
        # Create a new Bridge with this Bridge as its Bridge
        # @see BridgeBuilder#initialize
        def bridge(*args, **kwargs, &block)
          super(*args, bridge: self, **kwargs, &block)
        end

        # Create a new Thing with this Bridge as its Bridge
        # @see ThingBuilder#initialize
        def thing(*args, **kwargs, &block)
          super(*args, bridge: self, **kwargs, &block)
        end
      end

      # The ChannelBuilder DSL allows you to customize a channel
      class ChannelBuilder
        attr_accessor :label
        attr_reader :uid, :config, :type

        #
        # Constructor for ChannelBuilder
        #
        # This class is instantiated by the {ThingBuilder#channel #channel} method inside a {Builder#thing} block.
        #
        # @param [String] uid The channel's ID.
        # @param [String, ChannelTypeUID, :trigger] type The concrete type of the channel.
        # @param [String] label The channel label.
        # @param [thing] thing The thing associated with this channel.
        #   This parameter is not needed for the {ThingBuilder#channel} method.
        # @param [String] group The group name.
        # @param [Hash] config Channel configuration. The keys can be strings or symbols.
        #
        def initialize(uid, type, label = nil, thing:, group: nil, config: {})
          @thing = thing

          uid = uid.to_s
          uid_segments = uid.split(org.openhab.core.common.AbstractUID::SEPARATOR)
          group_segments = uid_segments.last.split(org.openhab.core.thing.ChannelUID::CHANNEL_GROUP_SEPARATOR)
          if group
            if group_segments.length == 2
              group_segments[0] = group
            else
              group_segments.unshift(group)
            end
            uid_segments[-1] = group_segments.join(org.openhab.core.thing.ChannelUID::CHANNEL_GROUP_SEPARATOR)
          end
          @uid = org.openhab.core.thing.ChannelUID.new(thing.uid, uid_segments.last)
          unless type.is_a?(org.openhab.core.thing.type.ChannelTypeUID)
            type = org.openhab.core.thing.type.ChannelTypeUID.new(thing.uid.binding_id, type)
          end
          @type = type
          @label = label
          @config = config.transform_keys(&:to_s)
        end

        # @!visibility private
        def build
          org.openhab.core.thing.binding.builder.ChannelBuilder.create(uid)
             .with_kind(kind)
             .with_type(type)
             .with_configuration(Core::Configuration.new(config))
             .build
        end

        private

        def kind
          if @type == :trigger
            org.openhab.core.thing.type.ChannelKind::TRIGGER
          else
            org.openhab.core.thing.type.ChannelKind::STATE
          end
        end
      end
    end
  end
end
