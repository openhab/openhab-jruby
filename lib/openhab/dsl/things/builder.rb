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
      # @example Create a Thing within a Bridge
      #   things.build do
      #     bridge "mqtt:broker:mosquitto", config: { host: "127.0.0.1", enableDiscovery: false } do
      #       thing "mqtt:topic:window1", "My Window Sensor" do
      #         channel "contact1", "contact", config: {
      #           stateTopic: "zigbee2mqtt/window1/contact",
      #           on: "false",
      #           off: "true"
      #         }
      #       end
      #     end
      #   end
      #
      #   items.build do
      #     contact_item Window1_Contact, channel: "mqtt:topic:window1:contact1"
      #   end
      #
      # @example Create a Thing separately from the Bridge
      #   things.build do
      #     bridge = bridge "mqtt:broker:mosquitto", config: { host: "127.0.0.1", enableDiscovery: false }
      #
      #     thing "mqtt:topic:window1", "My Window Sensor", bridge: bridge do
      #       channel "contact1", "contact", config: {
      #         stateTopic: "zigbee2mqtt/window1/contact",
      #         on: "false",
      #         off: "true"
      #       }
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

        def initialize(provider, update: false)
          @provider = Core::Things::Provider.current(provider)
          @update = update
        end

        # Create a new Bridge
        # @see BridgeBuilder#initialize
        def bridge(...)
          build(BridgeBuilder, ...)
        end

        # Create a new Thing
        # @see ThingBuilder#initialize
        def thing(...)
          build(ThingBuilder, ...)
        end

        private

        def build(klass, *args, **kwargs, &block)
          builder = klass.new(*args, **kwargs)
          builder.parent_builder = self if builder.respond_to?(:parent_builder=)
          builder.instance_eval(&block) if block
          thing = builder.build

          if DSL.things.key?(thing.uid)
            raise ArgumentError, "Thing #{thing.uid} already exists" unless @update

            unless (old_thing = provider.get(thing.uid))
              raise FrozenError, "Thing #{thing.uid} is managed by #{thing.provider}"
            end

            if thing.config_eql?(old_thing)
              logger.debug { "Not replacing existing thing #{thing.uid}" }
              thing = old_thing
            else
              provider.update(thing)
            end
          else
            provider.add(thing)
          end
          thing.enable(enabled: builder.enabled) unless builder.enabled.nil?

          Core::Things::Proxy.new(thing)
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
          @builder = org.openhab.core.thing.binding.builder.ThingBuilder unless instance_variable_defined?(:@builder)
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

            predefined_channels = self.class.thing_factory_helper
                                      .create_channels(thing_type, uid, self.class.config_description_registry)
                                      .to_h { |channel| [channel.uid, channel] }
            new_channels = channels.to_h { |channel| [channel.uid, channel] }
            merged_channels = predefined_channels.merge(new_channels) do |_key, predefined_channel, new_channel|
              predefined_channel.configuration.merge!(new_channel.configuration)
              predefined_channel
            end
            @channels = merged_channels.values
          end

          builder = @builder.create(thing_type_uid, uid)
                            .with_label(label)
                            .with_location(location)
                            .with_configuration(configuration)
                            .with_bridge(bridge_uid)
                            .with_channels(channels)

          builder.with_properties(thing_type.properties) if thing_type

          builder.build
        end

        private

        def thing_type
          @thing_type ||= self.class.thing_type_registry.get_thing_type(thing_type_uid)
        end
      end

      # The BridgeBuilder DSL allows you to customize a thing
      class BridgeBuilder < ThingBuilder
        # @!visibility private
        attr_accessor :parent_builder

        # Constructor for BridgeBuilder
        # @see ThingBuilder#initialize
        def initialize(uid, label = nil, binding: nil, type: nil, bridge: nil, location: nil, config: {}, enabled: nil)
          @builder = org.openhab.core.thing.binding.builder.BridgeBuilder
          super
        end

        # Create a new Bridge with this Bridge as its Bridge
        # @see BridgeBuilder#initialize
        def bridge(*args, **kwargs, &)
          parent_builder.bridge(*args, bridge: self, **kwargs, &)
        end

        # Create a new Thing with this Bridge as its Bridge
        # @see ThingBuilder#initialize
        def thing(*args, **kwargs, &)
          parent_builder.thing(*args, bridge: self, **kwargs, &)
        end
      end

      # The ChannelBuilder DSL allows you to customize a channel
      class ChannelBuilder
        attr_accessor :label
        attr_reader :uid,
                    :config,
                    :type,
                    :default_tags,
                    :properties,
                    :description,
                    :auto_update_policy

        #
        # Constructor for ChannelBuilder
        #
        # This class is instantiated by the {ThingBuilder#channel #channel} method inside a {Builder#thing} block.
        #
        # @param [String] uid The channel's ID.
        # @param [String, ChannelTypeUID, :trigger] type The concrete type of the channel.
        # @param [String] label The channel label.
        # @param [Thing] thing The thing associated with this channel.
        #   This parameter is not needed for the {ThingBuilder#channel} method.
        # @param [String] description The channel description.
        # @param [String] group The group name.
        # @param [Hash] config Channel configuration. The keys can be strings or symbols.
        # @param [Hash] properties The channel properties.
        # @param [String,Symbol,Semantics::Tag,Array<String,Symbol,Semantics::Tag>] default_tags
        #   The default tags for this channel.
        # @param [:default, :recommend, :veto, org.openhab.core.thing.type.AutoUpdatePolicy] auto_update_policy
        #   The channel's auto update policy.
        # @param [String] accepted_item_type The accepted item type. If nil, infer the item type from the channel type.
        #
        def initialize(uid,
                       type,
                       label = nil,
                       thing:,
                       description: nil,
                       group: nil,
                       config: nil,
                       properties: nil,
                       default_tags: nil,
                       auto_update_policy: nil,
                       accepted_item_type: nil)
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
          @config = config&.transform_keys(&:to_s)
          @default_tags = Items::Tags.normalize(*Array.wrap(default_tags))
          @properties = properties&.transform_keys(&:to_s)
          @description = description
          @accepted_item_type = accepted_item_type
          return unless auto_update_policy

          @auto_update_policy = org.openhab.core.thing.type.AutoUpdatePolicy.value_of(auto_update_policy.to_s.upcase)
        end

        # @!visibility private
        def build
          org.openhab.core.thing.binding.builder.ChannelBuilder.create(uid)
             .with_kind(kind)
             .with_type(type)
             .tap do |builder|
               builder.with_label(label) if label
               builder.with_configuration(Core::Configuration.new(config)) if config && !config.empty?
               builder.with_default_tags(Set.new(default_tags).to_java) unless default_tags.empty?
               builder.with_properties(properties) if properties
               builder.with_description(description) if description
               builder.with_auto_update_policy(auto_update_policy) if auto_update_policy
               builder.with_accepted_item_type(accepted_item_type) if accepted_item_type
             end
             .build
        end

        # @!attribute [r] accepted_item_type
        # @return [String] The accepted item type.
        def accepted_item_type
          @accepted_item_type ||= type.channel_type&.item_type
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
