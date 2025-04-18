# frozen_string_literal: true

require "forwardable"

require_relative "hash"

module OpenHAB
  module Core
    module Items
      module Metadata
        #
        # {NamespaceHash} represents the full metadata for the item.
        #
        # It implements the entire interface of {::Hash}.
        #
        # Keys are namespaces, values are always {Hash}, though assignment allows
        # using a {Hash}, a String, a `::Hash`, or an array of two items:
        # `[String, ::Hash]`.
        #
        # All keys are converted to strings.
        #
        class NamespaceHash
          include EmulateHash
          extend Forwardable

          class << self
            #
            # @return [org.openhab.core.items.MetadataRegistry]
            #
            # @!visibility private
            def registry
              @registry ||= OSGi.service("org.openhab.core.items.MetadataRegistry")
            end
          end

          java_import org.openhab.core.items.MetadataKey
          private_constant :MetadataKey

          def_delegators :keys,
                         :length,
                         :size

          # @!visibility private
          def initialize(item_name = nil, hash = nil)
            @item_name = item_name || "-"
            @hash = item_name.nil? ? (hash || {}) : nil
          end

          # Is this object attached to an actual Item?
          # @return [true,false]
          def attached?
            @hash.nil?
          end

          # @!visibility private
          def dup
            self.class.new(nil, transform_values(&:dup))
          end

          # Implicit conversion to {::Hash}
          # @return [::Hash]
          def to_hash
            each.to_h { |namespace, meta| [namespace, meta] }
          end
          alias_method :to_h, :to_hash
          alias_method :to_map, :to_hash
          private :to_map

          # @!visibility private
          def fetch(key, *default_value, &block)
            key = key.to_s
            return @hash.fetch(key, *default_value, &block) unless attached?

            if default_value.length > 1
              raise ArgumentError, "Wrong number of arguments (given #{default_value.length + 1}, expected 1..2)"
            end

            logger.trace { "Getting metadata for item: #{@item_name}, namespace '#{key}'" }
            if (m = Provider.registry.get(MetadataKey.new(key, @item_name)))
              Hash.new(m)
            elsif block
              yield key
            elsif !default_value.empty?
              default_value.first
            else
              raise KeyError, "Key not found #{key.inspect}"
            end
          end

          #
          # Set the metadata namespace. If the namespace does not exist, it will be created
          #
          # @param value [Hash, Array[String, ::Hash], ::Hash<String, Object>]
          #
          # @return [Hash]
          #
          # @!visibility private
          def store(namespace, value)
            metadata = Hash.from_item(@item_name, namespace, value)
            return @hash[metadata.uid.namespace] = metadata unless attached?

            metadata.create_or_update
            metadata
          end

          #
          # Remove all the namespaces
          #
          # @!visibility private
          def clear
            if attached?
              provider = Provider.current(Thread.current[:openhab_providers]&.dig(:metadata_items, @item_name))
              provider.remove_item_metadata(@item_name)
              Thread.current[:openhab_providers]&.[](:metadata_namespaces)&.each_value do |namespace_provider|
                Provider.current(namespace_provider).remove_item_metadata(@item_name)
              end
            else
              @hash.clear
            end
          end

          # @!visibility private
          def compact
            to_hash
          end

          # @!visibility private
          def compact!
            # no action; impossible to have nil keys
            self
          end

          # @!visibility private
          def deconstruct_keys
            self
          end

          # @!visibility private
          def delete(namespace, &block)
            return @hash.delete(namespace.to_s, &block) unless attached?

            metadata = Hash.from_item(@item_name, namespace, nil)
            r = metadata.remove
            return yield(namespace) if block && !r

            Hash.new(r) if r
          end

          # @!visibility private
          def delete_if
            raise NotImplementedError unless block_given?

            each { |k, v| delete(k) if yield(k, v) }
            self
          end

          # @!visibility private
          def dig(key, *keys)
            m = self[key.to_s]
            return m if keys.empty?

            m&.dig(*keys)
          end

          #
          # Enumerates through all the namespaces
          #
          # @yieldparam [String] namespace
          # @yieldparam [Hash] metadata
          #
          # @!visibility private
          def each(&block)
            return @hash.each(&block) unless attached?
            return to_enum(:each) unless block

            Provider.registry.all.each do |meta|
              yield meta.uid.namespace, Hash.new(meta) if meta.uid.item_name == @item_name
            end
            self
          end
          alias_method :each_pair, :each

          # @!visibility private
          def each_key(&block)
            return @hash.each_key(&block) unless attached?
            return to_enum(:each_key) unless block

            if Provider.registry.respond_to?(:get_all_namespaces)
              keys.each(&block)
            else
              Provider.registry.all.each do |meta|
                yield meta.uid.namespace if meta.uid.item_name == @item_name
              end
            end
            self
          end

          # @!visibility private
          def each_value
            return @hash.each_value(&block) unless attached?
            return to_enum(:each_value) unless block_given?

            Provider.registry.all.each do |meta|
              yield Hash.new(meta) if meta.uid.item_name == @item_name
            end
            self
          end

          # @!visibility private
          def empty?
            return @hash.empty? unless attached?

            Provider.registry.all.each do |meta|
              return false if meta.uid.item_name == @item_name
            end
            true
          end

          # @!visibility private
          def fetch_values(*keys)
            return @hash.fetch_values(keys.map(&:to_s)) if attached?

            keys.each_with_object([]) do |key, res|
              key = key.to_s
              if (m = Provider.registry.get(MetadataKey.new(key, @item_name)))
                res << Hash.new(m)
              elsif block_given?
                res << yield(key)
              end
            end
          end

          # @!visibility private
          def hash
            ["metadata_namespace_hash", @item_name.hash]
          end

          #
          # @return [true,false] True if the given namespace exists, false otherwise
          #
          # @!visibility private
          def key?(key)
            key = key.to_s
            return @hash.key?(key) unless attached?

            !Provider.registry.get(MetadataKey.new(key, @item_name)).nil?
          end
          alias_method :member?, :key?

          # @!visibility private
          def keys
            if Provider.registry.respond_to?(:get_all_namespaces)
              return Provider.registry.get_all_namespaces(@item_name).to_a
            end

            each_key.to_a
          end

          # @!visibility private
          def replace(other)
            clear
            case other
            when ::Hash, NamespaceHash
              other.each do |namespace, new_meta|
                self[namespace] = new_meta
              end
            else
              raise ArgumentError, "Only supports Hash, or another item's metadata. '#{other.class}' was given."
            end
            self
          end

          # @!visibility private
          def select!
            raise NotImplementedError unless block_given?

            removed = false
            each do |k, v|
              unless yield(k, v)
                delete(k)
                removed = true
              end
            end
            return nil unless removed

            self
          end
          alias_method :filter!, :select!

          # @!visibility private
          def shift
            raise NotImplementedError
          end

          # @!visibility private
          def slice(*keys)
            keys.map!(&:to_s)
            return @hash.slice(*keys) unless attached?

            keys = keys.to_set
            r = {}
            Provider.registry.all.each do |meta|
              if meta.uid.item_name == @item_name && keys.include?(meta.uid.namespace)
                r[meta.uid.namespace] = Hash.new(meta)
              end
            end
            r
          end

          # @!visibility private
          def reject!
            raise NotImplementedError unless block_given?

            removed = false
            each do |k, v|
              if yield(k, v)
                delete(k)
                removed = true
              end
            end
            return nil unless removed

            self
          end

          # @!visibility private
          def transform_keys!(hash2 = nil)
            hash2 = hash2&.transform_keys(&:to_s)
            each_key do |k|
              if hash2
                next unless hash2.key?(k)

                self[hash2[k]] = delete(k)
              else
                new_k = yield k
                self[new_k] = delete(k)
              end
            end
            self
          end

          # @!visibility private
          def transform_values!
            raise NotImplementedError unless block_given?

            each do |k, v|
              new_v = yield(k, v)
              next if new_v.equal?(v)

              self[k] = new_v
            end
          end

          # @!visibility private
          def value?(value)
            each_value { |v| return true if v == value }
            false
          end
          alias_method :has_value?, :value?

          # @!visibility private
          def values
            each_value.to_a
          end

          # @!visibility private
          def values_at(*keys)
            keys.map(&self)
          end
        end
      end
    end
  end
end
