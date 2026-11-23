# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    # Reads persisted and file-based addon settings before OSGi is running.
    # @!visibility private
    class AddonSettings
      PID = "org.openhab.automation.jrubyscripting"

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
        result = persisted_properties.to_h
        config = ENV.fetch("OPENHAB_CONF", "/etc/openhab")
        files = Dir.glob(File.join(config, "services/*.cfg")).select { |path| File.file?(path) }
        exclusive = false
        files.sort_by { |path| [File.mtime(path), path] }.each do |path|
          exclusive = apply_file(path, result, exclusive)
        end
        result
      end

      # ConfigDispatcher applies files oldest first and overlays their values on ConfigAdmin.
      def apply_file(path, result, exclusive)
        lines = File.readlines(path, encoding: "UTF-8")
        exclusive_pid = lines.first&.match(/\Apid:\s*(.+?)\s*$/)&.captures&.first
        return exclusive if exclusive && exclusive_pid != PID

        pid = exclusive_pid || File.basename(path, ".cfg")
        pid = "org.openhab.#{pid}" unless pid.include?(".")
        values = result.dup
        values.clear if exclusive_pid == PID
        lines.each do |line|
          line = line.strip
          next if line.empty? || line.start_with?("#", "pid:")

          key, separator, value = line.partition("=")
          next if separator.empty?

          if key.include?(":")
            pid, key = key.split(":", 2).map(&:strip)
            pid = "org.openhab.#{pid}" unless pid.include?(".")
          end
          return exclusive if exclusive_pid && pid != exclusive_pid

          values[key.strip] = value.strip if pid == PID
        end
        result.replace(values)
        exclusive || exclusive_pid == PID
      end

      def persisted_properties
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
