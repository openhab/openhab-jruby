# frozen_string_literal: true

require "rake/packagetask"

require "bundler/gem_tasks"

require "English"
require "time"

PACKAGE_DIR = "pkg"

TMP_DIR = File.expand_path("tmp")
OPENHAB_DIR = File.join(TMP_DIR, "openhab")

CLEAN << PACKAGE_DIR

DOC_FILES = %w[
  templates/default/fulldoc/html/js/app.js
  templates/default/layout/html/versions.erb
].freeze

VERSIONS_JS = "docs/js/versions.js"

def file_sub(file, old, new)
  contents = File.read(file)
  contents.gsub!(old, new)
  File.write(file, contents)
end

def add_archived_version(file, version)
  contents = File.read(file)
  contents.sub!(%r{(^\s*\]; // ARCHIVED_VERSIONS_MARKER)}, %(    "#{version}",\n\\1))
  File.write(file, contents)
end

desc "Update links in YARD doc navigation to mark the latest minor release as stable"
task :update_doc_links, [:old_version, :new_version] do |_t, args|
  old_version = Gem::Version.new(args[:old_version]).segments[0..1].join(".")
  new_version = Gem::Version.new(args[:new_version]).segments[0..1].join(".")

  next if old_version == new_version

  DOC_FILES.each { |file| file_sub(file, old_version, new_version) }
  add_archived_version(VERSIONS_JS, old_version)

  file_sub(".known_good_references", "/openhab-jruby/#{old_version}", "/openhab-jruby/#{new_version}")
end
