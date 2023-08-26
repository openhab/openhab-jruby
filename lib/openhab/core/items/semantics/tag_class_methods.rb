# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      module Semantics
        # @deprecated OH3.4 didn't have SemanticTag class

        #
        # Adds tag attributes to the semantic tag class
        #
        module TagClassMethods
          # @!visibility private
          java_import org.openhab.core.semantics.SemanticTags

          #
          # Returns the tag's string representation
          #
          # @return [String]
          #
          def to_s
            java_class.simple_name
          end

          #
          # Returns the tag's label
          #
          # @param [java.util.Locale] locale The locale that the label should be in, if available.
          #   When nil, the system's default locale is used.
          #
          # @return [String] The tag's label
          #
          def label(locale = nil)
            SemanticTags.get_label(java_class, locale || java.util.Locale.default)
          end

          #
          # Returns the tag's synonyms
          #
          # @param [java.util.Locale] locale The locale that the label should be in, if available.
          #   When nil, the system's default locale is used.
          #
          # @return [Array<String>] The list of synonyms in the requested locale.
          #
          def synonyms(locale = nil)
            unless SemanticTags.respond_to?(:get_synonyms)
              return java_class.get_annotation(org.openhab.core.semantics.TagInfo.java_class).synonyms
                               .split(",").map(&:strip)
            end

            SemanticTags.get_synonyms(java_class, locale || java.util.Locale.default).to_a
          end

          #
          # Returns the tag's description
          #
          # @param [java.util.Locale] locale The locale that the description should be in, if available.
          #   When nil, the system's default locale is used.
          #
          # @return [String] The tag's description
          #
          def description(locale = nil)
            unless SemanticTags.respond_to?(:get_description)
              return java_class.get_annotation(org.openhab.core.semantics.TagInfo.java_class).description
            end

            SemanticTags.get_description(java_class, locale || java.util.Locale.default)
          end
        end
      end
    end
  end
end
