# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    java_import org.openhab.core.config.core.Configuration

    # {Configuration} represents openHAB's {org.openhab.core.config.core.Configuration} data
    # with the full interface of {::Hash} and stringifies symbolic keys.
    class Configuration
      include Enumerable
      extend Forwardable

      # Make it act like a Hash
      def_delegators :get_properties,
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

      def_delegator :to_h, :inspect

      # @!visibility private
      alias_method :to_s, :inspect

      # @!visibility private
      def [](key)
        get(key.to_s)
      end

      # @!visibility private
      def []=(key, value)
        put(key.to_s, value)
      end
      alias_method :store, :[]=

      # @!visibility private
      def delete(key)
        remove(key.to_s)
      end

      # @!visibility private
      def key?(key)
        contains_key(key.to_s)
      end
      alias_method :has_key?, :key?
      alias_method :include?, :key?

      # @!visibility private
      def replace(new_pairs)
        set_properties(new_pairs.to_h.transform_keys(&:to_s))
        self
      end

      # @!visibility private
      alias_method :keys, :key_set

      # @!visibility private
      alias_method :hash, :hash_code

      # @!visibility private
      def dup
        new(self)
      end

      # @!visibility private
      def <(other)
        to_hash < other.to_hash.transform_keys(&:to_s)
      end

      # @!visibility private
      def <=(other)
        to_hash <= other.to_hash.transform_keys(&:to_s)
      end

      # @!visibility private
      def ==(other)
        return to_hash == other.transform_keys(&:to_s) if other.is_a?(Hash)

        equals(other)
      end

      # @!visibility private
      def >(other)
        to_hash > other.to_hash.transform_keys(&:to_s)
      end

      # @!visibility private
      def >=(other)
        to_hash >= other.to_hash.transform_keys(&:to_s)
      end

      # @!visibility private
      def assoc(key)
        to_h.assoc(key.to_s)
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
      def delete_if(&block)
        raise NotImplementedError unless block

        replace(to_h.delete_if(&block))
      end

      # @!visibility private
      def except(*keys)
        to_h.except(*keys.map(&:to_s))
      end

      # @!visibility private
      def dig(*keys)
        to_h.dig(*keys.map(&:to_s))
      end

      # @!visibility private
      def fetch(key, default = nil)
        get(key.to_s) || default || (block_given? && yield)
      end

      # @!visibility private
      def fetch_values(*keys, &block)
        to_h.fetch_values(*keys.map(&:to_s), &block)
      end

      # @!visibility private
      def keep_if(&block)
        select!(&block)
        self
      end

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

      # @!visibility private
      def select!(&block)
        raise NotImplementedError unless block?

        r = to_h.select!(&block)
        replace(r) if r
      end
      alias_method :filter!, :select!

      # @!visibility private
      def slice(*keys)
        to_h.slice(*keys.map(&:to_s))
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
        to_h.values_at(*keys.map(&:to_s))
      end
    end
  end
end
