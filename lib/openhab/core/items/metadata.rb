# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      # Contains classes wrapping interactions with item metadata.
      module Metadata
        autoload :Provider, "openhab/core/items/metadata/provider"
        autoload :NamespaceHash, "openhab/core/items/metadata/namespace_hash"
        autoload :Hash, "openhab/core/items/metadata/hash"
      end
    end
  end
end
