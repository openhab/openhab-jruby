# frozen_string_literal: true

require "delegate"

module OpenHAB
  module RSpec
    # @!visibility private
    module Mocks
      class AbstractStorageBasedTypeProviderWrappedStorageService < SimpleDelegator
        include org.openhab.core.storage.StorageService

        def initialize(parent, ruby_klass, java_klass)
          super(parent)
          @ruby_klass = ruby_klass
          @java_klass = java_klass
        end

        def getStorage(name, _class_loader)
          super(name.sub(@ruby_klass.name, @java_klass.name), @java_klass.class_loader)
        end
      end
    end
  end
end
