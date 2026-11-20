# frozen_string_literal: true

require "rake/tasklib"

module OpenHAB
  module Karaf
    # Rake tasks for maintaining a local test instance.
    #
    # @example Install in a Rakefile
    #   require "openhab/karaf/tasks"
    #   OpenHAB::Karaf::Tasks.new
    class Tasks < Rake::TaskLib
      # Define karaf:rebuild and karaf:refresh in the current Rake application.
      def initialize
        super
        namespace :karaf do
          desc "Remove and rebuild the .karaf test instance"
          task :rebuild do
            run("prepare(rebuild: true)")
          end

          desc "Refresh JSONDB and persistence data in the .karaf test instance"
          task :refresh do
            run("refresh")
          end
        end
      end

      private

      def run(operation)
        # Keep the harness's Java properties and class loaders out of the Rake process.
        ruby "-I",
             File.expand_path("../..", __dir__),
             "-r",
             "openhab/rspec/karaf",
             "-e",
             "OpenHAB::RSpec::Karaf.new(File.join(Dir.pwd, '.karaf')).#{operation}"
      end
    end
  end
end
