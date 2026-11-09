# frozen_string_literal: true

require "json"

def init
  options.objects = objects = run_verifier(options.objects)

  generate_assets
  options.files.each_with_index do |file, _i|
    serialize_file(file, file.title)
  end

  options.delete(:objects)

  objects.each do |object|
    serialize(object)
  rescue => e
    path = options.serializer.serialized_path(object)
    log.error "Exception occurred while generating '#{path}'"
    log.backtrace(e)
  end
end

def serialize(object)
  return generate_index if object == "index.json"

  super
end

def generate_assets
  @object = Registry.root

  layout = Object.new.extend(T("layout"))
  (layout.javascripts + javascripts_full_list +
      layout.stylesheets + stylesheets_full_list).uniq.each do |file|
    asset(file, file(file, true))
  end

  generate_index
end

def jsonify_classes(klass)
  children = run_verifier(klass.children).grep(CodeObjects::NamespaceObject)
  return if children.empty?

  children.map do |child|
    {
      u: url_for(child)[base_url.length..],
      n: child.name,
      s: (child.superclass&.name if child.is_a?(CodeObjects::ClassObject)),
      d: (1 if child.has_tag?(:deprecated)),
      c: jsonify_classes(child)
    }.compact
  end
end

def generate_index
  # u = url
  # n = name
  # s = superclass
  # p = parent/containing module
  # d = deprecated
  classes = jsonify_classes(Registry.root)

  methods = prune_method_listing(Registry.all(:method), false)
            .reject { |m| m.name.to_s.end_with?("=") && m.is_attribute? }
            .sort_by { |m| m.path.split("::") }
            .map do |method|
    {
      u: url_for(method)[base_url.length..],
      n: method.name(true),
      p: method.namespace.title,
      d: (1 if method.has_tag?(:deprecated))
    }
  end

  asset("index.json", {
    classes:,
    methods:
  }.to_json)
end
alias_method :generate_index_list, :generate_index
