# frozen_string_literal: true

module OpenHAB
  module CoreExt
    module Java
      java_import java.time.Instant

      # Extensions to {java.time.Instant}
      class Instant < java.lang.Object; end
    end
  end
end

Instant = OpenHAB::CoreExt::Java::Instant unless Object.const_defined?(:Instant)
