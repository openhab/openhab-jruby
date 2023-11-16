# frozen_string_literal: true

module YARD
  module Handlers
    module JRuby
      module Base
        class << self
          #
          # Creates an external link to java documentation for a java class.
          #
          # The supported classes are defined in the `javadocs` configuration option.
          #
          # Supported syntaxes:
          #   Package:
          #   - org.openhab.core => href_base/org/openhab/core/package-summary.html
          #
          #   Class:
          #   - org.openhab.core.OpenHAB => href_base/org/openhab/core/OpenHAB.html
          #   This doesn't get mistaken as a constant:
          #   - java.net.URI => href_base/java/net/URI.html
          #
          #   Constant: (To specify a constant, use Ruby's `::` syntax)
          #   - org.openhab.core.OpenHAB::DEFAULT_CONFIG_FOLDER =>
          #       href_base/org/openhab/core/OpenHAB.html#DEFAULT_CONFIG_FOLDER
          #
          #   Method:
          #   - org.openhab.core.OpenHAB#getVersion() => href_base/org/openhab/core/OpenHAB.html#getVersion()
          #   But can also work with constants, albeit not a valid Ruby syntax:
          #   - org.openhab.core.OpenHAB#version => href_base/org/openhab/core/OpenHAB.html#version
          #   - org.openhab.core.OpenHAB#DEFAULT_CONFIG_FOLDER =>
          #       href_base/org/openhab/core/OpenHAB.html#DEFAULT_CONFIG_FOLDER
          #
          #   Inner class:
          #   - org.openhab.core.config.core.ConfigDescriptionParameter::Type =>
          #       href_base/org/openhab/core/config/core/ConfigDescriptionParameter.Type.html
          #   - org.openhab.core.config.core.ConfigDescriptionParameter.Type =>
          #       href_base/org/openhab/core/config/core/ConfigDescriptionParameter.Type.html
          #
          #   Constant in inner class:
          #   - org.openhab.core.config.core.ConfigDescriptionParameter::Type::TEXT =>
          #       href_base/org/openhab/core/config/core/ConfigDescriptionParameter.Type.html#TEXT
          #   - org.openhab.core.config.core.ConfigDescriptionParameter.Type::TEXT =>
          #       href_base/org/openhab/core/config/core/ConfigDescriptionParameter.Type.html#TEXT
          #
          def infer_java_class(klass, inferred_type = nil, comments = nil, statement = nil)
            javadocs = YARD::Config.options.dig(:jruby, "javadocs") || {}

            href_base = javadocs.find { |package, _href| klass == package || klass.start_with?("#{package}.") }&.last
            return unless href_base

            components = klass.split(/\.(?=[A-Z])/, 2)
            components.unshift(*components.shift.split("."))
            components.push(components.pop.delete_suffix(".freeze"))

            class_first_char = components.last[0]
            if /#|::/.match?(components.last)
              parts = components.pop.rpartition(/#|::/)
              is_field = parts.last == parts.last.upcase
              # explicit method is fine, e.g. `org.openhab.core.OpenHAB#getVersion()`
              is_method = !is_field
              components.push(parts.first.gsub("::", "."), parts.last)
            else
              is_field = is_method = false
              if components.last.include?(".")
                parts = components.last.split(".")
                if (is_method = parts.last[0] == parts.last[0].downcase)
                  # implicit method is not supported, e.g. `org.openhab.core.OpenHAB.version`
                  # because we're not sure whether it should be #version() or #getVersion()
                  return
                end
              end
            end

            is_package = !is_method && !is_field && class_first_char != class_first_char.upcase

            inferred_type = CodeObjects::Java::FieldObject if is_field
            inferred_type = CodeObjects::Java::MethodObject if is_method
            inferred_type = CodeObjects::Java::PackageObject if is_package
            if inferred_type.nil?
              docstring = Docstring.parser.parse(comments || statement&.comments).to_docstring
              inferred_type = if docstring.has_tag?(:interface)
                                CodeObjects::Java::InterfaceObject
                              else
                                CodeObjects::Java::ClassObject
                              end
            end

            orig_klass = klass.dup

            # purposely calling gsub! to modify the caller's string
            # YARD doesn't handle java inner classes well, so we convert them to ruby
            klass.gsub!("::", ".")

            inferred_type.new(klass) do |o|
              o.source = statement if statement
              suffix = "/package-summary" if is_package
              field = "##{components.pop}" if is_field || is_method
              link = "#{href_base}#{components.join("/")}#{suffix}.html#{field}"
              o.docstring.add_tag(Tags::Tag.new(:see, orig_klass, nil, link)) unless o.docstring.has_tag?(:see)
            end
          end
        end

        def infer_java_class(statement, inferred_type = nil, comments = nil)
          return unless statement.is_a?(Parser::Ruby::AstNode)
          return unless statement.type == :call

          Base.infer_java_class(statement.source, inferred_type, comments, statement)
        end
      end
    end
  end
end
