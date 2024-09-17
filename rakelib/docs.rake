# frozen_string_literal: true

begin
  require "yard"
rescue LoadError
  return
end

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
end
