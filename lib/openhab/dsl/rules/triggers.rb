# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      # Contains helper classes for implementing triggers.
      # @!visibility private
      module Triggers
      end
    end
  end
end

Dir[File.expand_path("triggers/**/*.rb", __dir__)].each do |f|
  require f
end
