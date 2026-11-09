# frozen_string_literal: true

# @!visibility private
module Java::JavaxMeasure::Unit # rubocop:disable Style/ClassAndModuleChildren
  def inspect
    to_s
  end
end

# @!visibility private
module Java::JavaxMeasure::Dimension # rubocop:disable Style/ClassAndModuleChildren, Style/OneClassPerFile
  def inspect
    to_s
  end
end
