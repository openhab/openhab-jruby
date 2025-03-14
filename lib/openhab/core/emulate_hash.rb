# frozen_string_literal: true

require "forwardable"

module OpenHAB
  module Core
    #
    # Make a class acts like a Ruby Hash that supports indifferent keys.
    #
    # Methods that accepts keys will convert symbolic keys to string keys, but only shallowly.
    # This key indifference does not extend to Hash return values, however.
    # Hash return values will behave like a normal Hash
    # which treats symbolic and string keys differently.
    #
    # The including class must implement at least:
    # - `#to_map` to provide the hash-like data
    # - `#replace`
    # - `#store`
    # - Other methods and mutators as applicable to the underlying storage.
    #
    module EmulateHash
      include Enumerable
      extend Forwardable

      # Methods delegated to to_map
      DELEGATED_METHODS = %i[>
                             >=
                             <
                             <=
                             ==
                             any?
                             compact
                             deconstruct_keys
                             transform_keys
                             to_hash
                             length
                             size
                             compare_by_identity?
                             each
                             each_key
                             each_pair
                             each_value
                             equals
                             empty?
                             filter
                             flatten
                             has_value?
                             invert
                             key
                             keys
                             rassoc
                             reject
                             select
                             shift
                             to_a
                             to_h
                             to_hash
                             transform_keys
                             transform_values
                             value?
                             values].freeze
      private_constant :DELEGATED_METHODS

      def_delegators :to_map, *DELEGATED_METHODS

      def_delegator :to_h, :inspect

      # @!visibility private
      alias_method :to_s, :inspect

      # @!visibility private
      def except(*keys)
        to_map.except(*keys.map(&:to_s))
      end

      # @!visibility private
      def key?(key)
        to_map.key?(key.to_s)
      end
      alias_method :has_key?, :key?
      alias_method :include?, :key?

      #
      # @see https://ruby-doc.org/core/Hash.html#method-i-merge
      #
      # java.util.Map#merge is incompatible to Ruby's, but JRuby provides #ruby_merge for it
      #
      # @!visibility private
      def merge(*others, &)
        return self if others.empty?

        others.map! { |hash| hash.transform_keys(&:to_s) }
        map = to_map
        if map.respond_to?(:ruby_merge)
          map.ruby_merge(*others, &)
        else
          # fall back to #merge in case #to_map returns a Ruby Hash
          map.merge(*others, &)
        end
      end

      # @!visibility private
      def merge!(*others, &block)
        return self if others.empty?

        # don't call replace here so we don't touch other keys
        others.shift.merge(*others, &block).each do |key, value|
          value = yield key, self[key], value if key?(key) && block
          store(key, value)
        end
        self
      end
      alias_method :update, :merge!

      # @!visibility private
      def replace(hash)
        raise NotImplementedError
      end

      # @!visibility private
      def slice(*keys)
        to_map.slice(*keys.map(&:to_s))
      end

      # @!visibility private
      def fetch(key, *default, &)
        to_map.fetch(key.to_s, *default, &)
      end

      # @!visibility private
      def [](key)
        fetch(key, nil)
      end

      # @!visibility private
      def store(key, value)
        raise NotImplementedError
      end

      # @!visibility private
      def []=(key, value)
        store(key, value)
      end

      # @!visibility private
      def assoc(key)
        to_map.assoc(key.to_s)
      end

      # @!visibility private
      def clear
        replace({})
      end

      # @!visibility private
      def dig(key, *keys)
        to_map.dig(key.to_s, *keys)
      end

      # @!visibility private
      def compact!
        to_h.compact!&.then { |r| replace(r) }
      end

      # @!visibility private
      def delete_if(&block)
        raise NotImplementedError unless block

        replace(to_h.delete_if(&block))
      end

      # @!visibility private
      def keep_if(&)
        select!(&)
        self
      end

      # @!visibility private
      def select!(&block)
        raise NotImplementedError unless block

        to_h.select!(&block)&.then { |r| replace(r) }
      end
      alias_method :filter!, :select!

      # @!visibility private
      def reject!(&block)
        raise NotImplementedError unless block

        to_h.reject!(&block)&.then { |r| replace(r) }
      end

      # @!visibility private
      def fetch_values(*keys, &)
        to_map.fetch_values(*keys.map(&:to_s), &)
      end

      # @!visibility private
      def transform_keys!(...)
        replace(transform_keys(...))
      end

      # @!visibility private
      def transform_values!(&block)
        raise NotImplementedError unless block

        replace(transform_values(&block))
      end

      # @!visibility private
      def values_at(*keys)
        to_map.values_at(*keys.map(&:to_s))
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
      def default(*)
        nil
      end

      # @!visibility private
      def default_proc
        nil
      end

      # @!visibility private
      def to_proc
        ->(k) { self[k] }
      end
    end
  end
end
