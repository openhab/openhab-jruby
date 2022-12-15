# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      class Proxy
        class << self
          def reset_cache
            @proxies.clear
          end
        end
      end
    end
  end
end
