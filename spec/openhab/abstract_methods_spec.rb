# frozen_string_literal: true

RSpec.describe "Abstract Methods" do
  it "checks that all abstract Java methods are implemented" do
    missing_methods = +""
    klasses = [OpenHAB]
    inspected = klasses.to_set

    until klasses.empty?
      klass = klasses.shift
      klass.constants.each do |c|
        sub_const = klass.const_get(c)
        next if inspected.include?(sub_const)

        next unless sub_const.is_a?(Module) &&
                    sub_const.name&.start_with?("OpenHAB::") &&
                    !sub_const.name.include?("OpenHAB::RSpec::")

        klasses << sub_const
        inspected << sub_const
      end

      next unless klass.is_a?(Class)

      klass.ancestors.each do |ancestor|
        next if ancestor <= JavaProxy
        next unless ancestor.respond_to?(:java_class) && ancestor.java_class

        ancestor.java_class.declared_instance_methods.each do |method|
          next unless method.modifiers.anybits?(java.lang.reflect.Modifier::ABSTRACT)

          begin
            klass.instance_method(method.name)
          rescue NameError
            missing_methods << "#{method} on #{klass.name}\n"
          end
        end
      end
    end

    expect(missing_methods).to be_empty,
                               "The following abstract methods are not implemented: \n#{missing_methods.strip}"
  end
end
