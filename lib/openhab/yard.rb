# frozen_string_literal: true

Dir[File.expand_path("yard/**/*.rb", __dir__)].each do |f|
  require f
end

YARD::Templates::Template.extra_includes << OpenHAB::YARD::BaseHelper
YARD::Templates::Template.extra_includes << ->(opts) { OpenHAB::YARD::CodeRay::HtmlHelper if opts.format == :html }
YARD::Templates::Template.extra_includes << ->(opts) { OpenHAB::YARD::HtmlHelper if opts.format == :html }
YARD::Templates::Template.extra_includes << ->(opts) { OpenHAB::YARD::MarkdownHelper if opts.format == :markdown }

YARD::Templates::Engine.register_template_path File.expand_path("../../templates", __dir__)
YARD::Tags::Library.define_tag "Java Interface", :interface

YARD::Server.register_static_path(".")

#
# @!parse
#   # @!visibility private
#   module Comparable; end
#
#   # @!visibility private
#   module Forwardable; end
#
#   # @!visibility private
#   module Singleton; end
#
#   # Extensions to Ruby Numeric
#   class Numeric; end
#
#   # @!visibility private
#   class Object; end
#
#   # Extensions to Ruby Range
#   class Range; end
#
