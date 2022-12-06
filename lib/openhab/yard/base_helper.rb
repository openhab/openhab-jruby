# frozen_string_literal: true

require "nokogiri"

module OpenHAB
  module YARD
    # @!visibility private
    module BaseHelper
      def preprocess(text)
        html = Nokogiri::HTML5.fragment(text)

        context = if ENV["ADDON"]
                    :addon
                  else
                    :yard
                  end

        # process directives on which content is supposed to be included in this context
        node = html.children.first
        loop do
          break unless node

          next_node = node.next

          if node.comment? && (directive = MarkdownDirective.new(node)).directive?
            next_node = directive.process(context) || next_node
          end
          node = next_node
        end

        html.to_s
      end

      def link_object(obj, title = nil, *)
        ::YARD::Handlers::JRuby::Base.infer_java_class(obj) if obj.is_a?(String)
        obj = ::YARD::Registry.resolve(object, obj, true, true) if obj.is_a?(String)
        if obj.is_a?(::YARD::CodeObjects::Java::Base) && (see = obj.docstring.tag(:see))
          # link to the first see tag
          return linkify(see.name, title&.to_s || see.text)
        end

        super
      end
    end
  end
end
