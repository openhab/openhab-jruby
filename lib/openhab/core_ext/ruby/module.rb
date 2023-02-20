# frozen_string_literal: true

# Extensions to Module
class Module
  #
  # Returns the name of the class or module, without any containing module or package.
  #
  # @return [String, nil]
  #
  def simple_name
    return unless name

    @simple_name ||= java_class&.simple_name || name.split("::").last
  end
end
