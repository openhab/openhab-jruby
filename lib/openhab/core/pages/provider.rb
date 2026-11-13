# frozen_string_literal: true

require_relative "../ui/provider"

module OpenHAB
  module Core
    # MainUI page definitions.
    module Pages
      # Supplies Ruby pages to MainUI until the script is unloaded.
      class Provider < UI::Provider
        # @!visibility private
        def self.namespace
          "ui:page"
        end
      end
    end
  end
end
