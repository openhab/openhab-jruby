# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      module Semantics
        java_import org.openhab.core.semantics.SemanticTag

        # @since openHAB 4.0
        module SemanticTag
          # @attribute [r] uid
          #
          # The tag's full UID, including ancestors.
          #
          # @return [String]

          # @attribute [r] parent_uid
          #
          # The UID of the tag's parent.
          #
          # @return [String]

          # @attribute [r] name
          #
          # The tag's simple name.
          #
          # @return [String]

          # @attribute [r] label
          #
          # The tag's human readable label.
          #
          # @return [String]

          # @attribute [r] description
          #
          # The tag's full description.
          #
          # @return [String]

          # @attribute [r] synonyms
          #
          # Allowed synonyms for the tag.
          #
          # @return [java.util.List<String>]

          # @method localized(locale)
          #
          # Returns a new {SemanticTag SemanticTag} localized to the specified locale.
          #
          # @param locale [java.util.Locale] The locale to localize this tag to
          # @return [SemanticTag]

          # @!visibility private
          def <(other)
            check_type(other)
            uid != other.uid && uid.start_with?(other.uid)
          end

          # @!visibility private
          def <=(other)
            check_type(other)
            uid.start_with?(other.uid)
          end

          # @!visibility private
          def ==(other)
            check_type(other)
            uid == other.uid
          end

          # @!visibility private
          def >=(other)
            check_type(other)
            other.uid.start_with?(uid)
          end

          # @!visibility private
          def >(other)
            check_type(other)
            uid != other.uid && other.uid.start_with?(uid)
          end

          # @return [String]
          def inspect
            parent = "(#{parent_uid})" unless parent_uid.empty?
            "#<OpenHAB::Core::Items::Semantics::#{name}#{parent} " \
              "label=#{label.inspect} " \
              "description=#{description.inspect} " \
              "synonyms=#{synonyms.to_a.inspect}>"
          end

          private

          def check_type(other)
            raise ArgumentError, "comparison of #{other.class} with SemanticTag failed" unless other.is_a?(SemanticTag)
          end
        end
      end
    end
  end
end
