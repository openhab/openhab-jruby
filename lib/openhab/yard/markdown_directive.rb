# frozen_string_literal: true

require "nokogiri"

module OpenHAB
  module YARD
    # @!visibility private
    class MarkdownDirective
      attr_reader :comment, :context

      def initialize(comment)
        @comment = comment
        @lines = comment.text.split("\n")
        directive_text = @lines.first.strip

        @multiline = @lines.length > 1
        @directive = false
        return unless (match = directive_text.match(%r{^<(/)?(!)?([a-z]+)-only>$}))

        @closing = match[1]
        @context = match[3].to_sym
        @inverted = match[2]

        if closing? && multiline?
          log.warn "In file `#{file}':#{line}: Multiline closing directives are not allowed (#{directive_text})."
          return
        end
        @directive = true
      end

      def directive?
        @directive
      end

      def multiline?
        @multiline
      end

      def closing?
        @closing
      end

      def inverted?
        @inverted
      end

      def match?(context)
        result = context == self.context
        result = !result if inverted?
        result
      end

      def closing_directive
        return nil if multiline?

        unless instance_variable_defined?(:@closing_directive)
          next_node = @comment.next
          loop do
            return @closing_directive = nil unless next_node

            if next_node.comment?
              directive = MarkdownDirective.new(next_node)
              if directive.directive? &&
                 directive.closing? &&
                 directive.context == context &&
                 directive.inverted? == inverted?
                return @closing_directive = next_node
              end
            end

            next_node = next_node.next
          end
        end
        @closing_directive
      end

      def process(context)
        return unless directive?
        return if closing?

        matched = match?(context)

        # if it's a matched multiline, extract the contents and insert them directly,
        # and remove the comment
        if multiline?
          result = comment.next
          comment.before(Nokogiri::HTML5.fragment(@lines[1..].join("\n"))) if matched
          comment.remove
          return result
        end

        unless closing_directive
          log.warn "In file `#{file}':#{line}: Unmatched directive <#{"!" if inverted?}#{context}-only>."
          return
        end

        result = closing_directive.next

        unless matched
          # remove all nodes between the opening and closing directives
          comment.next.remove while comment.next != closing_directive
        end
        # now remove the directives themselves
        closing_directive.remove
        comment.remove
        result
      end

      def file
        ((defined?(@file) && @file) ? @file.filename : object.file) || "(unknown)"
      end

      def line
        return @line if instance_variable_defined?(@line)

        @line = (if defined?(@file) && @file
                   1
                 else
                   (object.docstring.line_range ? object.docstring.line_range.first : 1)
                 end) + (match ? $`.count("\n") : 0)
        @line += comment.line - 1
      end
    end
  end
end
