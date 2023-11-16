# frozen_string_literal: true

module YARD
  module CodeObjects
    module Java
      class MethodObject < CodeObjects::MethodObject
        include Base

        def type
          :method
        end
      end
    end
  end
end
