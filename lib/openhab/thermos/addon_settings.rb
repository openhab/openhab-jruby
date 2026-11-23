# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    # Reads ConfigAdmin's persisted addon settings before OSGi is running.
    # @!visibility private
    class AddonSettings
      def gem_home
        config = ENV.fetch("OPENHAB_CONF", "/etc/openhab")
        template = properties["gem_home"] || File.join(config, "automation/ruby/.gem/{RUBY_ENGINE_VERSION}")
        replacements = { "RUBY_ENGINE" => RUBY_ENGINE,
                         "RUBY_ENGINE_VERSION" => JRUBY_VERSION,
                         "RUBY_VERSION" => RUBY_VERSION }
        template.gsub(/\{(RUBY_ENGINE|RUBY_ENGINE_VERSION|RUBY_VERSION)\}/) { replacements.fetch(Regexp.last_match(1)) }
      end

      private

      def properties
        userdata = ENV.fetch("OPENHAB_USERDATA", "/var/lib/openhab")
        path = File.join(userdata, "config/org/openhab/automation/jrubyscripting.config")
        return {} unless File.file?(path)

        home = ENV.fetch("OPENHAB_HOME", "/usr/share/openhab")
        runtime = ENV.fetch("OPENHAB_RUNTIME", File.join(home, "runtime"))
        jars = Dir.glob(File.join(runtime,
                                  "system/org/apache/felix/org.apache.felix.configadmin/*",
                                  "org.apache.felix.configadmin-[0-9]*.jar"))
        jar = jars.max_by { |candidate| File.mtime(candidate) }
        raise "Cannot read addon settings: Felix ConfigAdmin JAR not found under #{runtime}/system" unless jar

        # ConfigAdmin also bundles OSGi interfaces. Never add it to JRuby's global
        # classpath: its interfaces would shadow Karaf's copies during startup.
        url = java.io.File.new(jar).to_uri.to_url
        loader = java.net.URLClassLoader.new([url].to_java(java.net.URL), java.lang.ClassLoader.platform_class_loader)
        handler = loader.load_class("org.apache.felix.cm.file.ConfigurationHandler")
        read = handler.get_method("read", java.io.InputStream.java_class)
        stream = java.io.FileInputStream.new(path)
        read.invoke(nil, stream)
      ensure
        stream&.close
        loader&.close
      end
    end
  end
end
