# frozen_string_literal: true

java_import org.objectweb.asm.ClassWriter
java_import org.objectweb.asm.Opcodes

module OpenHAB
  module Core
    module Items
      module Semantics
        #
        # Utility to add custom Semantic tags
        #
        # @!visibility private
        class CustomSemantic
          class << self
            #
            # Adds a custom semantic tag.
            #
            # @param [Symbol,String] name The name of the new semantic tag to add
            # @param [String, Semantics::Tag] parent The semantic class of the parent tag
            # @param [String] label An optional label. If not provided, it will be generated from name by
            #   splitting up the CamelCase with a space
            # @param [String] synonyms A comma separated list of synonyms.
            # @param [String] description A longer description.
            #
            # @return [Semantics::Tag,nil] The added semantic tag class,
            #   or nil if the tag had already been registered.
            #
            def add(name, parent, label: nil, synonyms: "", description: "")
              name = name.to_s

              return if name == self.class.name

              unless /^[A-Z][a-zA-Z0-9]+$/.match?(name)
                raise "Name must start with a capital letter and not contain any spaces"
              end

              class_loader = org.openhab.core.semantics.SemanticTags.java_class.class_loader

              parent = Semantics.const_get(parent) if parent.is_a?(String)
              valid_types = [Semantics::Location, Semantics::Equipment, Semantics::Point, Semantics::Property]
              type = valid_types.find { |t| parent == t || parent < t }
              raise "Parent must be one of #{valid_types} or their descendants" unless type

              type = type.java_class.simple_name.downcase
              class_name = "org.openhab.core.semantics.model.#{type}.#{name}"

              return unless class_loader.find_class(nil, class_name).nil?

              internal_parent_name = parent.java_class.name.tr(".", "/")
              internal_class_name = class_name.tr(".", "/")

              # CamelCaseALL99 -> Camel Case ALL 99
              label ||= name.gsub(/(([A-Z][a-z]+)|([A-Z][A-Z]+)|([0-9]+))/, " \\1").strip

              # Create the class/interface
              class_writer = ClassWriter.new(0)
              class_writer.visit(Opcodes::V11, Opcodes::ACC_PUBLIC + Opcodes::ACC_ABSTRACT + Opcodes::ACC_INTERFACE,
                                 internal_class_name, nil, "java/lang/Object", [internal_parent_name])

              # Add TagInfo Annotation
              class_writer.visit_source("Status.java", nil)
              parent.java_class.get_annotation(org.openhab.core.semantics.TagInfo.java_class).id.then do |parent_id|
                # Correct a bug in openhab, Semantics::Property's id is `MeasurementProperty` instead of Property
                parent_id = "Property" if parent_id == "MeasurementProperty" # @deprecated OH3.4

                annotation_visitor = class_writer.visit_annotation("Lorg/openhab/core/semantics/TagInfo;", true)
                annotation_visitor.visit("id", "#{parent_id}_#{name}")
                annotation_visitor.visit("label", label)
                annotation_visitor.visit("synonyms", synonyms)
                annotation_visitor.visit("description", description)
                annotation_visitor.visit_end
              end

              class_writer.visit_end
              byte_code = class_writer.to_byte_array

              java_klass = class_loader.define_class(class_name, byte_code, 0, byte_code.length)

              register_tag(java_klass)
              java_klass.ruby_class
            end

            private

            def register_tag(java_klass)
              id = java_klass.get_annotation(org.openhab.core.semantics.TagInfo.java_class).id
              type = id.split("_").first

              # Add to org.openhab.core.semantics.model.location.Locations.LOCATIONS
              type_plural = "#{type.sub(/y$/, "ie")}s" # pluralize, Property -> Properties, Location -> Locations
              field_name = type_plural.upcase.to_sym
              type_aggregator = java_import("org.openhab.core.semantics.model.#{type.downcase}.#{type_plural}").first
              type_aggregator.field_reader field_name
              members_list = type_aggregator.send(field_name)
              members_list.add(java_klass)

              # Add to org.openhab.core.semantics.SemanticTags.TAGS
              # by calling the private method SemanticTags.addTagSet
              semantic_tags = org.openhab.core.semantics.SemanticTags.java_class
              add_tag_set = semantic_tags.declared_method(:addTagSet, java.lang.Class.java_class)
              add_tag_set.accessible = true
              add_tag_set.invoke(semantic_tags, java_klass)
              add_tag_set.accessible = false
            end
          end
        end

        #
        # Adds custom semantic tags.
        #
        # @return [Semantics::Tag] The added semantic tag class
        #
        # @overload self.add(**tags)
        #   Quickly add one or more semantic tags using the default label, empty synonyms and descriptions.
        #
        #   @param [kwargs] **tags One or more `tag` => `parent` pairs
        #   @return [Boolean] true if all tags were added successfully
        #
        #   @example Add one semantic tag `Balcony` whose parent is `Semantics::Outdoor` (Location)
        #     Semantics.add(Balcony: Semantics::Outdoor)
        #
        #   @example Add multiple semantic tags
        #     Semantics.add(Balcony: Semantics::Outdoor,
        #                   SecretRoom: Semantics::Room,
        #                   Motion: Semantics::Property)
        #
        # @overload self.add(label: nil, synonyms: "", description: "", **tags)
        #   Add a custom semantic tag with extra details.
        #
        #   @example
        #     Semantics.add(SecretRoom: Semantics::Room, label: "My Secret Room",
        #       synonyms: "HidingPlace", description: "A room that requires a special trick to enter")
        #
        #   @param [String,nil] label Optional label. When nil, infer the label from the tag name,
        #     converting `CamelCase` to `Camel Case`
        #   @param [String] synonyms A comma separated list of synonyms for this tag.
        #   @param [String] description A longer description of the tag.
        #   @param [kwargs] **tags Exactly one pair of `tag` => `parent`
        #   @return [Boolean] true if the tag was added successfully
        #
        def self.add(label: nil, synonyms: "", description: "", **tags)
          raise "Tags must be specified" if tags.empty?
          if (tags.length > 1) && !(label.nil? && synonyms.empty? && description.empty?)
            raise "Additional options can only be specified when creating one tag"
          end

          tags.map do |name, parent|
            CustomSemantic.add(name, parent, label: label, synonyms: synonyms, description: description)
          end.any?(&:!)
        end

        #
        # Automatically looks up new semantic classes and adds them as `constants`
        #
        # @return [Tag, nil]
        #
        def self.const_missing(sym)
          logger.trace("const missing, performing Semantics Lookup for: #{sym}")

          TAGS_DB.each do |db|
            db.stream.for_each do |tag|
              return const_set(tag.simple_name.to_sym, tag.ruby_class) if tag.simple_name.to_sym == sym
            end
          end

          nil
        end
      end
    end
  end
end
