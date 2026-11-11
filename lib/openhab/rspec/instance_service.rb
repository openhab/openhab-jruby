# frozen_string_literal: true

require "fileutils"

module OpenHAB
  module RSpec
    # What Karaf's InstanceServiceImpl does to clone an instance, as close to its methods as Ruby allows. Karaf's own
    # cloneInstance can't be told to skip anything: it fails on the first entry the user running rspec can't read, and
    # the real instance creates some of those itself, with explicit modes. Each difference is commented where it is.
    #
    # @!visibility private
    class InstanceService
      # Karaf's copy ignores these, at any depth: lock files, active txlog files and an instance's bundle cache
      IGNORED = /\A(lock|cache\.lock|transaction_\d+\.log)\z|\.instance\z/
      private_constant :IGNORED

      # Not Karaf: backups, such as ConfigAdmin's of each config. They name the real instance's files just like the
      # configs do, and nothing in a clone needs them.
      BACKUP = /\.bak\z/
      private_constant :BACKUP

      # Not Karaf: skipped in the top level of the real userdata only. The harness deletes the cache from the clone
      # anyway. openHAB creates entries in tmp and openhab-start-level that the user running rspec can't read. Hidden
      # entries are the openHAB user's home directory clutter (.cache, .npm, .ssh, ...) when userdata is that user's
      # home, as it is for the Debian package.
      UNCOPIED_USERDATA = %w[cache openhab-start-level].freeze
      private_constant :UNCOPIED_USERDATA

      # Not Karaf: made, empty, whether or not the real userdata has them. The harness's java.io.tmpdir is inside the
      # clone, so tmp itself has to exist.
      EMPTY_USERDATA = %w[tmp].freeze
      private_constant :EMPTY_USERDATA

      # @param service [org.apache.karaf.instance.core.internal.InstanceServiceImpl]
      def initialize(service)
        @service = service
      end

      def clone_instance(name, clone_name, clone_location)
        raise ArgumentError, "Instance #{clone_name} already exists" if @service.get_instance(clone_name)

        instance = @service.get_instance(name)
        raise ArgumentError, "Instance #{name} not found" unless instance

        # copy instance directory
        location = instance.location
        copy(location, clone_location)
        # create the properties map including the instance name and location
        # Not Karaf: binary, since a properties file is Latin-1 as often as it is UTF-8
        props = { name.b => clone_name.b, location.b => clone_location.b }

        # filtering clone files
        filter_resource(clone_location, "etc/custom.properties", props)
        filter_resource(clone_location, "etc/org.apache.karaf.management.cfg", props)
        filter_resource(clone_location, "etc/org.apache.karaf.shell.cfg", props)
        filter_resource(clone_location, "etc/system.properties", props)
        filter_resource(clone_location, "bin/karaf", props)
        filter_resource(clone_location, "bin/start", props)
        filter_resource(clone_location, "bin/stop", props)
        filter_resource(clone_location, "bin/karaf.bat", props)
        filter_resource(clone_location, "bin/start.bat", props)
        filter_resource(clone_location, "bin/stop.bat", props)
        # Not Karaf: before the clone is registered, so that a clone that is registered is a finished one
        fill_management_config(clone_location)
        # add the clone instance to the registry: the instance list that redirect_instances made
        instance_list = java.io.File.new("#{clone_location}/instances/instance.properties")
        properties = org.apache.felix.utils.properties.Properties.new(instance_list)
        index = properties.get("count").to_i
        properties.put("count", (index + 1).to_s)
        properties.put("item.#{index}.name", clone_name)
        properties.put("item.#{index}.root", "false")
        properties.put("item.#{index}.loc", clone_location)
        properties.put("item.#{index}.pid", "0")
        java_opts = org.apache.karaf.instance.core.internal.InstanceServiceImpl::DEFAULT_JAVA_OPTS
        properties.put("item.#{index}.opts", java_opts)
        properties.save
      end

      private

      # Not Karaf: top_level is the userdata directory itself, whose entries have the skips above
      def copy(source, destination, top_level: true)
        name = File.basename(source)
        # ignore lock files, active txlog files and instance bundles cache
        # Not Karaf: but not the userdata directory itself, whatever it is called, or nothing would be cloned
        return if !top_level && (IGNORED.match?(name) || BACKUP.match?(name))

        # The userdata directory itself is not an entry to skip: without it there would be no clone
        unless top_level || readable?(source)
          warn "Not cloning #{source}: the user running the specs can't read it"
          return
        end
        # Opening a pipe would wait for a writer, and a socket or a device can't be copied
        if special_file?(source)
          warn "Not cloning #{source}: it is neither a file nor a directory"
          return
        end

        if File.directory?(source)
          FileUtils.mkdir_p(destination)
          EMPTY_USERDATA.each { |child| FileUtils.mkdir_p(File.join(destination, child)) } if top_level
          Dir.children(source).each do |child|
            # Karaf's test is "contains", and it is as loose as it looks: an entry at any depth with instances or lib
            # anywhere in its name is left out
            next if child.include?("instances") || child.include?("lib")
            next if top_level && (child.start_with?(".") || (UNCOPIED_USERDATA + EMPTY_USERDATA).include?(child))

            copy(File.join(source, child), File.join(destination, child), top_level: false)
          end
        else
          # Not FileUtils.copy_file, which keeps the mode: a read-only file would be a read-only file in the clone, and
          # the harness rewrites some of them.
          IO.copy_stream(source, destination)
        end
      # Readability was checked above, so this is an entry that disappeared: the real instance is running. Any other
      # failure, one on the clone's side or a full disk say, would leave a clone that is registered and then reused, so
      # it is raised.
      rescue Errno::ENOENT, Errno::ENOTDIR => e
        raise if top_level || File.exist?(source)

        FileUtils.rm_f(destination) if File.file?(destination)
        warn "Not cloning #{source}: #{e.message}"
      end

      def readable?(path)
        File.readable?(path) && (!File.directory?(path) || File.executable?(path))
      end

      def special_file?(path)
        File.exist?(path) && !File.file?(path) && !File.directory?(path)
      end

      # An openHAB install can have an empty management config. Give the clone the default ports, in its own copy and
      # never in the real instance's.
      def fill_management_config(basedir)
        file = File.join(basedir, "etc/org.apache.karaf.management.cfg")
        return unless File.file?(file) && File.empty?(file)

        File.write(file, <<~TEXT)
          # This file was autogenerated by openhab-scripting.
          # Feel free to customize.
          rmiRegistryPort = 1099
          rmiServerPort = 44444
        TEXT
      end

      def filter_resource(basedir, path, props)
        file = File.join(basedir, path)
        bak = "#{file}.bak"
        return unless File.file?(file)

        # rename the file to the backup one
        File.rename(file, bak)
        # copy and filter the bak file back to the original name
        File.open(bak, "rb") do |source|
          File.open(file, "wb") { |target| copy_and_filter_resource(source, target, props) }
        end
        # remove the bak file
        File.delete(bak)
      end

      def copy_and_filter_resource(source, target, props)
        # Not Karaf, which reads a line at a time so that it writes the platform's line ending: these keep their own
        source.each_line { |line| target.write(filter(line, props)) }
      end

      # Not Karaf, which applies the entries one after the other in the order of a HashMap, so a clone path that
      # contains the instance's name can be rewritten again. These are replaced in one pass.
      def filter(line, props)
        todo = props.dup
        line.gsub(Regexp.union(props.keys)) { |match| todo.delete(match) { match } }
      end
    end
  end
end
