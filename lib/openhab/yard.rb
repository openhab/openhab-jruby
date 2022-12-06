# frozen_string_literal: true

require "byebug"

Dir[File.expand_path("yard/**/*.rb", __dir__)].sort.each do |f|
  require f
end

YARD::Templates::Template.extra_includes << OpenHAB::YARD::BaseHelper
YARD::Templates::Template.extra_includes << ->(opts) { OpenHAB::YARD::HtmlHelper if opts.format == :html }
YARD::Templates::Template.extra_includes << ->(opts) { OpenHAB::YARD::MarkdownHelper if opts.format == :markdown }
YARD::Templates::Engine.register_template_path File.expand_path("../../templates", __dir__)
YARD::Tags::Library.define_tag "Java Interface", :interface

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
