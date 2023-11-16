# frozen_string_literal: true

module YARD
  module CodeObjects
    module Java
      #
      # Represents a java.lang.Class
      #
      # Which might be a class, an enum, or an interface
      module Base
        module ClassMethods
          def new(name, _suffix = nil)
            # _suffix is given when it encounters a class with ::, e.g. org.openhab.core.OpenHAB::DEFAULT_CONFIG_FOLDER

            super(:root, name)
          end
        end

        def self.included(klass)
          klass.singleton_class.include(ClassMethods)
        end

        def visibility
          :private
        end

        def simple_name
          name.to_s.split(".").last
        end
      end
    end
  end
end
