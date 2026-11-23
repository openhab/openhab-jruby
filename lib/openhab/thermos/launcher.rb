# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require "rbconfig"

module OpenHAB
  module Thermos
    # Launches both server processes with the same JRuby distribution.
    # @!visibility private
    class Launcher
      RUBY_ENVIRONMENT = %w[GEM_HOME
                            GEM_PATH
                            GEM_ROOT
                            RUBY_ROOT
                            RUBY_ENGINE
                            RUBY_VERSION
                            RUBYOPT
                            RUBYLIB
                            BUNDLE_BIN_PATH].freeze
      JVM_OPTIONS = %w[--add-opens=java.base/java.io=ALL-UNNAMED
                       --add-opens=java.base/java.nio.channels=ALL-UNNAMED
                       --add-opens=java.base/sun.nio.ch=ALL-UNNAMED].freeze

      def initialize(project_root)
        @project_root = project_root
      end

      def environment
        (RUBY_ENGINE == "jruby") ? {} : RUBY_ENVIRONMENT.to_h { |key| [key, nil] }
      end

      def command(jvm_options: [])
        jar = if RUBY_ENGINE == "jruby"
                java.lang.System.get_property("thermos.jruby.jar")
              else
                embedded_jar
              end
        return [RbConfig.ruby, *jvm_options.map { |option| "-J#{option}" }] unless jar

        java_home = ENV["JAVA_HOME"]
        executable = (java_home && !java_home.empty?) ? File.join(java_home, "bin", "java") : "java"
        [executable,
         *(JVM_OPTIONS + jvm_options).uniq,
         "-Dthermos.jruby.jar=#{jar}",
         "-cp",
         jar,
         "org.jruby.Main",
         "-r",
         File.expand_path("embedded.rb", __dir__)]
      end

      private

      def embedded_jar
        home = ENV.fetch("OPENHAB_HOME", "/usr/share/openhab")
        runtime = ENV.fetch("OPENHAB_RUNTIME", File.join(home, "runtime"))
        userdata = ENV.fetch("OPENHAB_USERDATA", "/var/lib/openhab")
        roots = [File.join(runtime, "system"),
                 File.join(userdata, "tmp", "mvn"),
                 File.join(userdata, "tmp", "kar"),
                 File.join(home, "userdata", "tmp", "mvn"),
                 File.join(home, "userdata", "tmp", "kar"),
                 File.join(home, "addons"),
                 File.join(@project_root, "addons")]
        jars = roots.flat_map do |root|
          Dir.glob(File.join(root, "**", "org.openhab.automation.jrubyscripting-*.jar"))
        end
        jar = jars.select { |path| File.file?(path) && File.readable?(path) }
                  .max_by { |path| [File.mtime(path), path] }
        return File.expand_path(jar) if jar

        raise ClientError, "Cannot find the jrubyscripting addon. Set OPENHAB_HOME, OPENHAB_RUNTIME, or " \
                           "OPENHAB_USERDATA to your openHAB installation, or retry with JRuby; " \
                           "once the server is running, you can switch to CRuby for the client."
      end
    end
  end
end
