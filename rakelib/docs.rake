# frozen_string_literal: true

begin
  require "yard"
rescue LoadError
  return
end

require "stringio"
require "pathname"

namespace :docs do
  yard_dir = File.join("docs", "yard")

  CLEAN << yard_dir
  CLEAN << ".yardoc"

  desc "Generate Yard Docs"
  task :yard do
    YARD::Rake::YardocTask.new do |t|
      t.files = ["lib/**/*.rb"] # optional
      t.stats_options = ["--list-undoc"] # optional
    end
  end

  desc "Generate Add-on's README.md"
  task :addon do
    base = Pathname(__FILE__).dirname
    tmp_dir = base / ".." / "tmp"
    tmp_dir.mkpath
    output_file = tmp_dir / "README.md"

    output = StringIO.new
    begin
      $stdout = output
      YARD::CLI::Display.new.run(
        "-f",
        "markdown",
        "-o",
        "https://openhab.github.io/openhab-jruby/main",
        "file:USAGE.md"
      )
      output_file.write(output.string)
    ensure
      $stdout = STDOUT
    end
    puts "Generated #{output_file}"
  end
end
