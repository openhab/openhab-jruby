# frozen_string_literal: true

def stylesheets
  super + %w[css/fonts.css css/navbar.css css/sidebar.css css/coderay.css]
end

def meta_description
  default = "Documentation for openhab-scripting JRuby helper library."
  return "#{object.docstring} - #{default}" unless object.docstring.blank?

  @file&.attributes&.dig(:description) || default
end
