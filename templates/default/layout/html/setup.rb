# frozen_string_literal: true

def stylesheets
  super + %w[css/fonts.css css/navbar.css css/sidebar.css css/coderay.css]
end

def meta_description
  default = "Documentation for openhab-scripting JRuby helper library."
  return "#{strip_links(object.docstring)} - #{default}" unless object.docstring.blank?

  @file&.attributes&.dig(:description) || default
end

# Extracts the description from YARD-style and markdown-style links
#   "{ClassName} text [Title](url)" => "ClassName text Title"
#   "{ClassName Class Title} text [Title](url)" => "Class Title text Title"
def strip_links(text)
  text.gsub(/\{(.+?)\}/) { $1.split(" ", 2).last }.gsub(/\[(.*?)\]\(.*?\)/, "\\1")
end
