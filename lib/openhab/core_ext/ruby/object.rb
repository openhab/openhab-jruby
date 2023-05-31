# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Ruby
      # @!visibility private
      module Object
        class << self
          attr_reader :top_self
        end

        # @!visibility private
        module ClassMethods
          # capture methods defined at top level (which get added to Object)
          def method_added(method)
            return super unless equal?(::Object)

            if DSL.private_instance_methods.include?(method)
              # Duplicate methods that conflict with DSL onto `main`'s singleton class,
              # so that they'll take precedence over DSL's method.
              Object.top_self.singleton_class.define_method(method, instance_method(method))
            end

            super
          end
        end
      end
    end
  end
end
