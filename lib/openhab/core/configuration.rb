# frozen_string_literal: true

require "forwardable"
require_relative "emulate_hash"

module OpenHAB
  module Core
    java_import org.openhab.core.config.core.Configuration

    #
    # {Configuration} represents openHAB's {org.openhab.core.config.core.Configuration} data
    # with the full interface of {::Hash}.
    #
    # All keys are converted to strings.
    #
    class Configuration
      include EmulateHash
      extend Forwardable

      alias_method :to_map, :properties
      private :to_map

      # @!visibility private
      def [](key)
        get(key.to_s)
      end

      # @!visibility private
      def store(key, value)
        put(key.to_s, value)
      end

      # @!visibility private
      def delete(key)
        key = key.to_s
        return yield(key) if block_given? && !key?(key)

        remove(key)
      end

      # @!visibility private
      def key?(key)
        contains_key(key.to_s)
      end

      # @!visibility private
      def replace(new_pairs)
        set_properties(new_pairs.to_h.transform_keys(&:to_s))
        self
      end

      # @!visibility private
      alias_method :keys, :key_set

      # @!visibility private
      def dup
        self.class.new(self)
      end

      # @!visibility private
      def ==(other)
        if !other.is_a?(self.class) && other.respond_to?(:to_hash)
          return to_hash == other.to_hash.transform_keys(&:to_s)
        end

        equals(other)
      end
    end
  end
end
