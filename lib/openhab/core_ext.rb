# frozen_string_literal: true

Dir[File.expand_path("core_ext/**/*.rb", __dir__)].each do |f|
  require f
end

module OpenHAB
  # Extensions to core classes
  module CoreExt
    # Extensions to core Java classes
    module Java
    end

    # Extensions to core Ruby classes
    module Ruby
    end
  end
end
