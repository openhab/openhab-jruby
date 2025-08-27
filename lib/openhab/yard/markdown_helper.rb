# frozen_string_literal: true

module OpenHAB
  module YARD
    # @!visibility private
    module MarkdownHelper
      include ::YARD::Templates::Helpers::HtmlHelper

      # @group Linking Objects and URLs

      def diskfile
        resolve_links(super)
      end

      # mostly copied from HTMLHelper
      def resolve_links(text)
        blockquotes = false
        result = text.gsub(%r{(```)|(\\|!)?\{(?!\})(\S+?)(?:\s([^\}]*?\S))?\}(?=[\W<]|.+</|$)}m) do |str|
          blockquote = $1
          escape = $2
          name = $3
          title = $4
          match = $&
          if blockquote
            blockquotes = !blockquotes
            next str
          end
          next str if blockquotes

          next(match[1..]) if escape

          next(match) if name[0, 1] == "|"

          if object.is_a?(String)
            object
          else
            link = linkify(name, title)
            if (link == name || link == title) && ("#{name} #{link}" !~ /\A<a\s.*>/)
              match = /(.+)?(\{#{Regexp.quote name}(?:\s.*?)?\})(.+)?/.match(text)
              file = ((defined?(@file) && @file) ? @file.filename : object.file) || "(unknown)"
              line = (if defined?(@file) && @file
                        1
                      else
                        (object.docstring.line_range ? object.docstring.line_range.first : 1)
                      end) + (match ? $`.count("\n") : 0)
              if match
                log.warn "In file `#{file}':#{line}: Cannot resolve link to #{name} from text#{match ? ":" : "."}\n" \
                         "\t#{"..." if match[1]}#{match[2].delete("\n")}#{"..." if match[3]}"
                # Don't strip the link. This is so literals like {RUBY_ENGINE_VERSION} remain as they are,
                # not stripped to "RUBY_ENGINE_VERSION"
                next str
              end
            end

            link
          end
        end

        # re-link files in docs/*.md. They're written so they work on github without any
        # processing
        result.gsub!(%r{\[([A-Za-z0-9,. ]+)\]\(([A-Za-z0-9./-]+)\)}) do |str|
          title = $1
          target = $2
          next str unless File.dirname(target) == "docs" && File.extname(target) == ".md"

          basename = File.basename(target, ".md")
          "[#{title}](#{serializer.basepath}/file.#{basename}.html)"
        end

        result
      end

      # mostly copied from HTMLHelper
      def link_object(obj, title = nil, anchor = nil, relative = true) # rubocop:disable Style/OptionalBooleanParameter
        return title if obj.nil?

        obj = ::YARD::Registry.resolve(object, obj, true, true) if obj.is_a?(String)

        was_const = false
        # Re-link references to constants that are aliases to their target. But keep
        # their current title.
        while obj.is_a?(::YARD::CodeObjects::ConstantObject) && obj.target
          title ||= h(object.relative_path(obj)).to_s
          was_const = true
          obj = obj.target
        end
        return link_object(obj, title, anchor, relative) if was_const

        title = if title
                  title.to_s
                elsif object.is_a?(::YARD::CodeObjects::Base)
                  # Check if we're linking to a class method in the current
                  # object. If we are, create a title in the format of
                  # "CurrentClass.method_name"
                  if obj.is_a?(::YARD::CodeObjects::MethodObject) && obj.scope == :class && obj.parent == object
                    h([object.name, obj.sep, obj.name].join)
                  elsif obj.title != obj.path
                    h(obj.title)
                  else
                    h(object.relative_path(obj))
                  end
                else
                  h(obj.title)
                end
        return title unless serializer
        return title if obj.is_a?(::YARD::CodeObjects::Proxy)

        link = url_for(obj, anchor, relative)
        link ? link_url(link, title, title: h("#{obj.title} (#{obj.type})")) : title
      rescue ::YARD::Parser::UndocumentableError
        log.warn "The namespace of link #{obj.inspect} is a constant or invalid."
        title || obj.to_s
      end

      def url_for(obj, anchor = nil, relative = true) # rubocop:disable Style/OptionalBooleanParameter
        link = nil
        return link unless serializer
        return link if obj.is_a?(::YARD::CodeObjects::Base) && run_verifier([obj]).empty?

        if obj.is_a?(::YARD::CodeObjects::Base) && !obj.is_a?(::YARD::CodeObjects::NamespaceObject)
          # If the obj is not a namespace obj make it the anchor.
          anchor = obj
          obj = obj.namespace
        end

        objpath = serializer.serialized_path(obj)
        return link unless objpath

        relative = false if object == ::YARD::Registry.root
        if relative
          fromobj = object
          if object.is_a?(::YARD::CodeObjects::Base) &&
             !object.is_a?(::YARD::CodeObjects::NamespaceObject)
            fromobj = owner
          end

          from = serializer.serialized_path(fromobj)
          link = File.relative_path(from, objpath)
        else
          link = File.join(serializer.basepath, objpath)
        end

        link + (anchor ? "##{urlencode(anchor_for(anchor))}" : "")
      end

      def link_url(url, title = nil, _params = nil)
        title ||= url
        "[#{title}](#{url})"
      end
    end
  end
end
