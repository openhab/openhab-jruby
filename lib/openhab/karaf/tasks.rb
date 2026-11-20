# frozen_string_literal: true

require "rake/tasklib"
require "openhab/rspec/configuration"

module OpenHAB
  module Karaf
    # Rake tasks for maintaining a local test instance.
    #
    # @example Install in a Rakefile
    #   require "openhab/karaf/tasks"
    #   OpenHAB::Karaf::Tasks.new
    class Tasks < Rake::TaskLib
      # Location of the test instance to maintain.
      # @return [String]
      attr_accessor :karaf_path

      # Define karaf:rebuild and karaf:refresh in the current Rake application.
      # @yield [self] Configure the tasks before they are defined.
      def initialize
        super
        yield self if block_given?
        @karaf_path ||= OpenHAB::RSpec::Configuration.karaf_path

        namespace :karaf do
          desc "Remove and rebuild the Karaf test instance"
          task :rebuild do
            run("prepare(rebuild: true)")
          end

          desc "Refresh JSONDB and persistence data in the Karaf test instance"
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
             "OpenHAB::RSpec::Karaf.new(#{karaf_path&.to_s&.dump || "nil"}).#{operation}"
      end
    end
  end
end
