# frozen_string_literal: true

# This is used by log_spec.rb to test logger names for libraries located in other files

module LogModule
  class MyClass # rubocop:disable Lint/EmptyClass
  end
end

def mylib_logger_name
  logger.name
end

module OpenHAB
  module Core
    module Events
      class AbstractEvent
        def logger_name
          logger.name
        end
      end
    end
  end
end
