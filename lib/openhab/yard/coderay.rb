# frozen_string_literal: true

require "coderay"

module OpenHAB
  module YARD
    module CodeRay
      module HtmlHelper
        ::CodeRay::Scanners.list.each do |scanner|
          define_method(:"html_syntax_highlight_#{scanner}") do |source|
            ::CodeRay.scan(source, scanner).html
          end
        end
      end
    end
  end
end
