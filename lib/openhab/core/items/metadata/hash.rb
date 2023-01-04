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
        # @!attribute [rw] value
        #   @return [String] The main value for the metadata namespace.
        # @!attribute [r] namespace
        #   @return [String]
        #
        class Hash
          java_import org.openhab.core.items.Metadata
          private_constant :Metadata

          include Enumerable

          extend Forwardable
          def_delegators :@metadata, :configuration, :hash, :to_s, :uid, :value
          private :configuration

          # @!method to_hash
          #   Implicit conversion to {::Hash}.
          #   @return [::Hash]

          # Make it act like a Hash; some methods can be handled by
          # java.util.Map, others we have to convert to a Ruby Hash first, and
          # still others (mutators) must be manually implemented below.
          def_delegators :configuration,
                         :any?,
                         :compact,
                         :compare_by_identity?,
                         :deconstruct_keys,
                         :default,
                         :default_proc,
                         :each,
                         :each_key,
                         :each_pair,
                         :each_value,
                         :empty?,
                         :filter,
                         :flatten,
                         :has_value?,
                         :invert,
                         :key,
                         :keys,
                         :length,
                         :rassoc,
                         :reject,
                         :select,
                         :shift,
                         :size,
                         :to_a,
                         :to_h,
                         :to_hash,
                         :transform_keys,
                         :transform_values,
                         :values,
                         :value?

          def_delegator :uid, :namespace

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
            provider.update(@metadata)
          end

          # @!visibility private
          def create_or_update
            return unless attached?

            javaify
            (p = provider).get(uid) ? p.update(@metadata) : p.add(@metadata)
          end

          # @!visibility private
          def remove
            provider.remove(uid)
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
          def [](key)
            configuration[key.to_s]
          end

          # @!visibility private
          def []=(key, value)
            key = key.to_s
            new_config = to_h
            new_config[key] = value
            replace(new_config)
            value # rubocop:disable Lint/Void
          end
          alias_method :store, :[]=

          # @!visibility private
          def assoc(key)
            configuration.assoc(key.to_s)
          end

          # @!visibility private
          def clear
            replace({})
          end

          # @!visibility private
          def compact!
            replace(compact)
          end

          # @!visibility private
          def compare_by_identity
            raise NotImplementedError
          end

          # @!visibility private
          def default=(*)
            raise NotImplementedError
          end

          # @!visibility private
          def default_proc=(*)
            raise NotImplementedError
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

          # @!visibility private
          def delete_if(&block)
            raise NotImplementedError unless block

            replace(to_h.delete_if(block))
          end

          # @!visibility private
          def dig(key, *keys)
            configuration.dig(key.to_s, *keys)
          end

          # @!visibility private
          def except(*keys)
            to_h.except(*keys.map(&:to_s))
          end

          # @!visibility private
          def fetch(key, &block)
            configuration.fetch(key.to_s, &block)
          end

          # @!visibility private
          def fetch_values(*keys, &block)
            configuration.fetch_values(*keys.map(&:to_s), &block)
          end

          # @!visibility private
          def keep_if(&block)
            select!(&block)
            self
          end

          # @!visibility private
          def key?(key)
            configuration.key?(key.to_s)
          end
          alias_method :include?, :key?
          alias_method :has_key?, :key?
          alias_method :member?, :key?

          # @!visibility private
          def merge!(*others, &block)
            return self if others.empty?

            new_config = to_h
            others.each do |h|
              new_config.merge!(h.transform_keys(&:to_s), &block)
            end
            replace(new_config)
          end
          alias_method :update, :merge!

          # @!visibility private
          def reject!(&block)
            raise NotImplementedError unless block

            r = to_h.reject!(&block)
            replace(r) if r
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
          def select!(&block)
            raise NotImplementedError unless block?

            r = to_h.select!(&block)
            replace(r) if r
          end
          alias_method :filter!, :select!

          # @!visibility private
          def slice(*keys)
            configuration.slice(*keys.map(&:to_s))
          end

          # @!visibility private
          def to_proc
            ->(k) { self[k] }
          end

          # @!visibility private
          def transform_keys!(*args, &block)
            replace(transform_keys(*args, &block))
          end

          # @!visibility private
          def transform_values!(&block)
            raise NotImplementedError unless block

            replace(transform_values(&block))
          end

          # @!visibility private
          def values_at(*keys)
            configuration.values_at(*keys.map(&:to_s))
          end

          # @!visibility private
          def inspect
            return to_h.inspect if value.empty?
            return value.inspect if configuration.empty?

            [value, to_h].inspect
          end
          remove_method :to_s
          alias_method :to_s, :inspect

          #
          # @raise [FrozenError] if the provider is not a
          #   {org.openhab.core.common.registry.ManagedProvider ManagedProvider} that can be updated.
          # @return [org.openhab.core.common.registry.ManagedProvider]
          #
          def provider
            preferred_provider = Provider.current(
              Thread.current[:openhab_providers]&.dig(:metadata_items, uid.item_name) ||
                Thread.current[:openhab_providers]&.dig(:metadata_namespaces, uid.namespace),
              self
            )

            if attached?
              provider = Provider.registry.provider_for(uid)
              return preferred_provider unless provider

              unless provider.is_a?(org.openhab.core.common.registry.ManagedProvider)
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
