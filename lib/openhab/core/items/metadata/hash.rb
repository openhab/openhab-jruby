# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    module Items
      module Metadata
        #
        # {Hash} represents the configuration for a single metadata namespace.
        #
        # It implements the entire interface of {::Hash}.
        #
        # All keys are converted to strings.
        #
        # As a special case, a #== comparison can be done against a [value, config] array.
        # @example
        #   MyItem.metadata[:namespace] = "value", { key: "value" }
        #   MyItem.metadata[:namespace] == ["value", { "key" => "value" }] #=> true
        #
        # @!attribute [rw] value
        #   @return [String] The main value for the metadata namespace.
        # @!attribute [r] namespace
        #   @return [String]
        #
        class Hash
          java_import org.openhab.core.items.Metadata
          private_constant :Metadata

          # Mutators are manually implemented below.
          include EmulateHash
          extend Forwardable

          def_delegators :@metadata, :configuration, :hash, :uid, :value
          private :configuration

          def_delegator :uid, :namespace

          alias_method :to_map, :configuration
          private :to_map

          class << self
            # @!visibility private
            def from_item(item_name, namespace, value)
              namespace = namespace.to_s
              value = case value
                      when Hash
                        return value if value.uid.item_name == item_name && value.uid.namespace == namespace

                        [value.value, value.send(:configuration)]
                      when Array
                        raise ArgumentError, "Array must contain 2 elements: value, config" if value.length != 2

                        [value.first, (value.last || {}).transform_keys(&:to_s)]
                      when ::Hash then ["", value.transform_keys(&:to_s)]
                      else [value.to_s, {}]
                      end
              new(Metadata.new(org.openhab.core.items.MetadataKey.new(namespace.to_s, item_name), *value))
            end

            # @!visibility private
            def from_value(namespace, value)
              from_item("-", namespace, value)
            end
          end

          # @!visibility private
          def initialize(metadata = nil)
            @metadata = metadata
          end

          # @!visibility private
          def dup
            new(Metadata.new(org.openhab.core.items.MetadataKey.new(uid.namespace, "-"), value, configuration))
          end

          # Is this object attached to an actual Item?
          # @return [true,false]
          def attached?
            uid.item_name != "-"
          end

          # @!attribute [r] item
          #   @return [Item, nil] The item this namespace is attached to.
          def item
            return nil unless attached?

            DSL.items[uid.item_name]
          end

          # @!visibility private
          def commit
            return unless attached?

            javaify
            provider!.update(@metadata)
          end

          # @!visibility private
          def create_or_update
            return unless attached?

            javaify
            (p = provider!).get(uid) ? p.update(@metadata) : p.add(@metadata)
          end

          # @!visibility private
          def remove
            provider!.remove(uid)
          end

          # @!visibility private
          def eql?(other)
            return true if equal?(other)
            return false unless other.is_a?(Hash)
            return false unless value == other.value

            configuration == other.configuration
          end

          #
          # Set the metadata value
          #
          def value=(value)
            @metadata = org.openhab.core.items.Metadata.new(uid, value.to_s, configuration)
            commit
          end

          # @!visibility private
          def <(other)
            if other.is_a?(Hash)
              return false if attached? && uid == other.uid
              return false unless value == other.value
            end

            configuration < other
          end

          # @!visibility private
          def <=(other)
            if other.is_a?(Hash)
              return true if attached? && uid == other.uid
              return false unless value == other.value
            end

            configuration <= other
          end

          # @!visibility private
          def ==(other)
            if other.is_a?(Hash)
              return false unless value == other.value

              return configuration == other.configuration
            elsif value.empty? && other.respond_to?(:to_hash)
              return configuration == other.to_hash
            elsif other.is_a?(Array)
              return other == [value, configuration]
            end
            false
          end

          # @!visibility private
          def >(other)
            if other.is_a?(Hash)
              return false if attached? && uid == other.uid
              return false unless value == other.value
            end

            configuration > other
          end

          # @!visibility private
          def >=(other)
            if other.is_a?(Hash)
              return true if attached? && uid == other.uid
              return false unless value == other.value
            end

            configuration >= other
          end

          # @!visibility private
          def store(key, value)
            key = key.to_s
            new_config = to_h
            new_config[key] = value
            replace(new_config)
            value
          end

          # @!visibility private
          def delete(key)
            key = key.to_s
            new_config = to_h
            return yield(key) if block_given? && !new_config.key?(key)

            old_value = new_config.delete(key)
            replace(new_config)
            old_value
          end

          #
          # Replace the configuration with a new {::Hash}.
          #
          # @param [::Hash] new_config
          # @return [self]
          #
          def replace(new_config)
            @metadata = org.openhab.core.items.Metadata.new(uid, value, new_config.transform_keys(&:to_s))
            commit
            self
          end

          # @!visibility private
          def inspect
            return to_h.inspect if value.empty?
            return value.inspect if configuration.empty?

            [value, to_h].inspect
          end

          # @return [org.openhab.core.common.registry.Provider, nil]
          def provider
            Provider.registry.provider_for(uid)
          end

          #
          # @raise [FrozenError] if the provider is not a
          #   {org.openhab.core.common.registry.ManagedProvider ManagedProvider} that can be updated.
          # @return [org.openhab.core.common.registry.ManagedProvider]
          #
          def provider!
            preferred_provider = Provider.current(
              Thread.current[:openhab_providers]&.dig(:metadata_items, uid.item_name) ||
                Thread.current[:openhab_providers]&.dig(:metadata_namespaces, uid.namespace),
              self
            )

            if attached?
              provider = self.provider
              return preferred_provider unless provider

              unless provider.is_a?(ManagedProvider)
                raise FrozenError, "Cannot modify metadata from provider #{provider.inspect} for #{uid}."
              end

              if preferred_provider != provider
                logger.warn("Provider #{preferred_provider.inspect} cannot be used with #{uid}; " \
                            "reverting to provider #{provider.inspect}. " \
                            "This may cause unexpected issues, like metadata persisting that you did not expect to.")
                preferred_provider = provider
              end

            end
            preferred_provider
          end

          private

          #
          # @see https://github.com/openhab/openhab-core/issues/3169
          #
          # in the meantime, force the serialization round-trip right now
          #
          def javaify
            mapper = Provider.registry.managed_provider.get.storage.entityMapper

            @metadata = mapper.from_json(mapper.to_json_tree(@metadata), Metadata.java_class)
          end
        end
      end
    end
  end
end
