# frozen_string_literal: true

require "nokogiri"
require "uri"

module OpenHAB
  module YARD
    # @!visibility private
    module HtmlHelper
      def base_url
        if serializer.is_a?(::YARD::Server::DocServerSerializer)
          abs_url(base_path(router.docs_prefix), "")
        else
          u = url_for("")
          u = "#{u}/" if !u.empty? && u[-1] != "/"
          u
        end
      end

      def url_for_search_index
        if serializer.is_a?(::YARD::Server::DocServerSerializer)
          url_for_list("index")
        else
          url_for("index.json")
        end
      end

      def html_markup_markdown(text)
        # Remove the "omit from toc" comments
        text.gsub!(" <!-- omit from toc -->", "")

        result = super

        html = Nokogiri::HTML5.fragment(result)
        # re-link files in docs/*.md. They're written so they work on github without any
        # processing
        unless serializer.is_a?(::YARD::Server::DocServerSerializer)
          html.css("a[href!='']").each do |link|
            uri = URI.parse(link["href"])
            next unless uri.relative? && File.extname(uri.path) == ".md"

            basename = File.basename(uri.path, ".md")
            uri.path = "file.#{basename}.html"
            link["href"] = uri.to_s
          end
        end

        # add the "#" mouse-over to header links
        html.css(Array.new(6) { |i| "h#{i + 1} > a.anchor" }.join(", ")).each do |anchor|
          anchor["class"] = "header-anchor"
          anchor.content = "#"
        end

        html.to_s
      end

      def link_url(url, title = nil, params = {})
        params.merge!(@link_attrs) if defined?(@link_attrs) && @link_attrs
        params[:class] = params.delete(:classes).join(" ") if params[:classes]
        super
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
