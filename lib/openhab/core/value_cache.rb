# frozen_string_literal: true

OpenHAB::Core.import_preset("cache")
unless defined?($sharedCache)
  $sharedCache = nil
  return
end

module OpenHAB
  module Core
    # @interface
    java_import org.openhab.core.automation.module.script.rulesupport.shared.ValueCache

    #
    # ValueCache is the interface used to access a
    # {OpenHAB::DSL.shared_cache shared cache} available between scripts and/or
    # rule executions.
    #
    # While ValueCache looks somewhat like a Hash, it does not support
    # iteration of the contained elements. So it's limited to strictly storing,
    # fetching, or removing known elements.
    #
    # Shared caches are _not_ persisted between openHAB restarts. And in fact,
    # if all scripts are unloaded that reference a particular key, that key is
    # removed.
    #
    # @note Only the {OpenHAB::DSL.shared_cache sharedCache} is exposed in Ruby.
    #   For a private cache, simply use an instance variable. See
    #   {file:docs/ruby-basics.md#variables Instance Variables}.
    #
    # @note Because every script or UI rule gets its own JRuby engine instance,
    #   you cannot rely on being able to access Ruby objects between them. Only
    #   objects that implement a Java interface that's part of Java or openHAB
    #   Core (such as Hash implements {java.util.Map}, or other basic
    #   datatypes) can be reliably stored and accessed from the shared cache.
    #   Likewise, you can use the cache to access data from other scripting
    #   languages, but they'll be all but useless in Ruby. It's best to stick
    #   to simple data types. If you're having troubles, serializing to_json
    #   before storing may help.
    #
    # @see https://www.openhab.org/docs/configuration/jsr223.html#cache-preset openHAB Cache Preset
    #
    # @example
    #   shared_cache.compute_if_absent(:execution_count) { 0 }
    #   shared_cache[:execution_count] += 1
    #
    module ValueCache
      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-5B-5D Hash#[]
      def [](key)
        get(key)
      end

      # @!method compute(key, &)
      #   Attempts to compute a mapping for the specified key and its current mapped value
      #   (or null if there is no current mapping).
      #   See {java.util.Map#compute(K,java.util.function.BiFunction) java.util.Map#compute} for details.
      #
      #   @param [String] key the key whose mapping is to be computed
      #   @yield [key, current_value] a block to compute the new value
      #   @yieldparam [String] key
      #   @yieldparam [Object] current_value the current value, or nil if there is no current mapping
      #   @yieldreturn [Object] new value, or nil to remove the key
      #
      #   @since openHAB 5.0

      #
      # Compute and store new value for key if the key is absent. This method is atomic.
      #
      # @param [String] key
      # @yieldreturn [Object] new value
      # @return [Object] new value or current value
      #
      def compute_if_absent(key, &)
        get(key, &)
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-5B-5D-3D Hash#[]=
      def []=(key, value)
        put(key, value)
      end
      alias_method :store, :[]

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-delete Hash#delete
      def delete(key)
        key = key.to_s # needed for remove below
        if block_given?
          fetch(key) do
            return yield(key)
          end
        end
        remove(key)
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-fetch Hash#fetch
      #
      # @example
      #   shared_cache.fetch(:key_from_another_script) # raises NoKeyError
      #
      def fetch(key, *default_value)
        if default_value.length > 1
          raise ArgumentError,
                "wrong number of arguments (given #{default_value.length + 1}, expected 0..1)"
        end

        if default_value.empty?
          key = key.to_s
          if block_given?
            get(key) do
              return yield(key)
            end
          else
            get(key) do
              raise KeyError.new("key not found: #{key.inspect}", key:)
            end
          end
        else
          get(key) { return default_value.first }
        end
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-assoc Hash#assoc
      def assoc(key)
        [key,
         fetch(key) do
           # return nil directly, without storing a value to the cache
           return nil
         end]
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-dig Hash#dig
      def dig(key, *identifiers)
        r = fetch(key) { return nil }
        r&.dig(*identifiers)
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-fetch_values Hash#fetch_values
      def fetch_values(*keys, &block)
        result = []
        keys.each do |key|
          if block
            result << fetch(key, &block)
          else
            has_value = true
            value = fetch(key) { has_value = false }
            result << value if has_value
          end
        end
        result
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-key-3F Hash#key?
      def key?(key)
        !!fetch(key) { return false }
      end
      alias_method :has_key?, :key?
      alias_method :include?, :key?
      alias_method :member?, :key?

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-merge-21 Hash#merge!
      def merge!(*other_hashes)
        other_hashes.each do |hash|
          hash.each do |(k, v)|
            k = k.to_s
            if block_given?
              dup = true
              old_value = fetch(k) do
                dup = false
              end
              self[k] = dup ? yield(k, old_value, v) : v
            else
              self[k] = v
            end
          end
        end
        self
      end
      alias_method :update, :merge!

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-slice Hash#slice
      def slice(*keys)
        result = {}
        keys.each do |k|
          k = k.to_s
          result[k] = self[k] if key?(k)
        end
        result
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-to_proc Hash#to_proc
      def to_proc
        ->(k) { self[k] }
      end

      # @see https://docs.ruby-lang.org/en/master/Hash.html#method-i-values_at Hash#values_at
      def values_at(*keys)
        keys.map do |k|
          self[k]
        end
      end

      #
      # Converts values before storing them in the cache.
      #
      # This is used to convert JRuby timers created with {OpenHAB::DSL.after} to openHAB timers.
      #
      # Because we generally can't store JRuby objects in the shared cache,
      # we can convert other things to Java objects here too as necessary.
      #
      # @!visibility private
      module ValueConverter
        # @!visibility private
        def get(key, &)
          key = key.to_s
          return super(key) unless block_given?

          super do
            convert(yield(key))
          end
        end

        # @!visibility private
        def put(key, value)
          key = key.to_s
          value = convert(value)
          super
        end

        private

        def convert(value)
          value.respond_to?(:to_java) ? value.to_java : value
        end
      end

      # We use prepend here instead of overriding the methods inside ValueCache module/interface
      # because the methods are defined in the implementation class
      $sharedCache.class.prepend(ValueConverter)
    end
  end
end
