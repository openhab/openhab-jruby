# frozen_string_literal: true

require_relative "../ui/provider"

module OpenHAB
  module Core
    # Reusable MainUI widget definitions.
    module Widgets
      # Supplies Ruby widgets to MainUI until the script is unloaded.
      class Provider < UI::Provider
        # @!visibility private
        def self.namespace
          "ui:widget"
        end
      end
    end
  end
end
