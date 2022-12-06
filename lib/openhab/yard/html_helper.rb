# frozen_string_literal: true

require "nokogiri"

module OpenHAB
  module YARD
    # @!visibility private
    module HtmlHelper
      def html_markup_markdown(text)
        result = super(preprocess(text))

        html = Nokogiri::HTML5.fragment(result)

        html.css("a").each do |a|
          next unless a["href"]

          href = URI.parse(a["href"])
          next unless href.relative?

          # re-link files in docs/*.md. They're written so they work on GitHub
          # without any processing
          href.path = "file.#{File.basename(href.path, ".md")}.html" if File.extname(href.path) == ".md"

          a["href"] = href.to_s
        end

        html.to_s
      end

      # have to completely replace this method. only change is the regex splitting
      # into parts now allows `.` as part of the identifier
      # rubocop:disable Style/NestedTernaryOperator, Style/StringConcatenation, Style/TernaryParentheses
      def format_types(typelist, brackets = true) # rubocop:disable Style/OptionalBooleanParameter
        return unless typelist.is_a?(Array)

        list = typelist.map do |type|
          type = type.gsub(/([<>])/) { h($1) }
          type = type.gsub(/([\w:.]+)/) { $1 == "lt" || $1 == "gt" ? $1 : linkify($1, $1) }
          "<tt>" + type + "</tt>"
        end
        list.empty? ? "" : (brackets ? "(#{list.join(", ")})" : list.join(", "))
      end
      # rubocop:enable Style/NestedTernaryOperator, Style/StringConcatenation, Style/TernaryParentheses
    end
  end
end
