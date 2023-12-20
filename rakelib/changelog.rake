# frozen_string_literal: true

directory "tmp"

desc "Generate Changelog"
task :changelog, %i[old_version new_version output] => ["tmp"] do |_task, args|
  old_version, new_version, new_filename = args.values_at(:old_version, :new_version, :output)
  unless old_version && new_version && new_filename
    raise ArgumentError, "old_version, new_version, and output arguments must be specified"
  end

  today = Time.now.strftime("%Y-%m-%d")
  header = "## [v#{new_version}](https://github.com/openhab/openhab-jruby/tree/v#{new_version}) (#{today})"

  release_notes = File.read(new_filename)
  release_notes = release_notes.gsub(/by @(\w+)/, 'by [@\1](https://github.com/\1)')
                               .gsub(%r{in (https://github.com/\S+/(\d+))}, 'in [#\2](\1)')
                               .gsub(%r{(Full Changelog..:) (https://\S+/compare/(\S+))}, '\1 [\3](\2)')
                               .gsub(/^(###.*)$/, "\n\\1\n")
                               .gsub(/^\* /, "- ")
                               .gsub(/\n{3,}/, "\n\n")
  File.write(new_filename, "#{header}\n#{release_notes}\n")

  insert_new_changelog(new_filename, main_filename: "CHANGELOG.md")
end

# Inserts the content of new_filename into the third line of the main_filename
# We want to preserve the first two lines which contain the changelog header
# Read/write line by line in case the changelog gets huge
def insert_new_changelog(new_filename, main_filename:)
  [main_filename, new_filename].each do |file|
    raise ArgumentError, "File '#{file}' doesn't exist" unless File.exist?(file)
  end

  temp_filename = "#{main_filename}.new"
  File.open(temp_filename, "w") do |temp_file|
    File.open(main_filename) do |main_file|
      2.times { temp_file.write main_file.gets } # Changelog header + blank line
      temp_file.write File.read(new_filename)
      main_file.each { |line| temp_file.write line }
    end
  end

  File.unlink(main_filename)
  File.rename(temp_filename, main_filename)
end
