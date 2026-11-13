# frozen_string_literal: true

require "fileutils"

module OpenHAB
  module RSpec
    # What Karaf's InstanceServiceImpl does to clone an instance, as close to its methods as Ruby allows. Karaf's own
    # cloneInstance can't be told to skip anything: it fails on the first entry the user running rspec can't read, and
    # the real instance creates some of those itself, with explicit modes. It also keeps the clone from writing to the
    # real instance. Each difference is commented where it is.
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

        location = instance.location
        # Not Karaf: before anything is copied, since copying an instance onto itself would empty its files
        self.class.refuse_nested_clone(location, clone_location)
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
        # Not Karaf: so that a clone that is registered can't write to the instance it was cloned from
        self.class.isolate_clone(location, clone_location)
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

        if top_level
          # The userdata directory itself is not an entry to skip: without it there would be no clone. One that can be
          # listed but not searched would be cloned as nothing but tmp, so it raises like one that can't be listed.
          raise Errno::EACCES, source if File.exist?(source) && !readable?(source)
        elsif !readable?(source)
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

      class << self
        # Not Karaf. The clone's ConfigAdmin store still names the files of the instance it was cloned from
        # (felix.fileinstall.filename), and the clone's fileinstall saves every config update, including the ones made
        # while starting up, to the file its config names. That would rewrite the real instance's etc/*.cfg files.
        # So make the clone refer only to itself, stop it from saving configs at all, and refuse to start if anything
        # still names the real instance.
        #
        # This is also called for every launch of the clone, which repairs one made by an older version.
        def isolate_clone(location, clone_location)
          location = File.expand_path(location)
          refuse_nested_clone(location, clone_location)
          refuse_symlinks(clone_location)
          remove_config_backups(clone_location)
          repoint_configs(location, clone_location)
          disable_config_save(clone_location)
          verify_isolation(location, clone_location)
        end

        # Not Karaf. Where the clone is, or is inside the real instance, rewriting its path would match the clone's own
        # files again on every launch. Where the real instance is inside the clone, the clone's files include the real
        # instance's, and they would be rewritten and deleted.
        def refuse_nested_clone(location, clone_location)
          real_location = real_path(location)
          real_clone = real_path(clone_location)
          return unless inside?(real_clone, real_location) || inside?(real_location, real_clone)

          raise ArgumentError,
                "The instance clone (#{clone_location}) is the instance it was cloned from (#{location}), " \
                "or inside it, or contains it"
        end

        private

        # The clone doesn't exist yet when it is being made: resolve what does, and append the rest. A ".." is only
        # collapsed in that rest, where there are no symlinks left for it to be wrong about. Not File.realpath, which
        # in JRuby collapses a ".." that follows a symlink before it follows the symlink.
        def real_path(path)
          java.nio.file.Paths.get(path).to_real_path.to_s
        rescue java.nio.file.NoSuchFileException
          File.expand_path(File.join(real_path(File.dirname(path)), File.basename(path)))
        rescue java.nio.file.FileSystemException => e
          raise ArgumentError, "Can't resolve #{path}: #{e.message}"
        end

        def inside?(path, directory)
          path == directory || path.start_with?("#{directory}/")
        end

        # Not Karaf. Karaf's copy and the harness give the clone no symlinks. One in the config store could lead to the
        # real instance: the glob doesn't descend into a symlinked directory, a dangling link has no path to resolve,
        # and the cleanup of the clone deletes in config/. So refuse to go on.
        def refuse_symlinks(clone_location)
          config = File.join(clone_location, "config")
          entries = Dir.glob("**/*", File::FNM_DOTMATCH, base: config).map { |entry| File.join(config, entry) }
          links = ([config] + entries).select { |entry| File.symlink?(entry) }
          return if links.empty?

          raise "The instance clone has symlinks in its config store, which could lead to the instance it was cloned " \
                "from: #{links.join(", ")}; refusing to change anything through them"
        end

        # Not Karaf. A file reached through a symlink, its own or a parent directory's, could belong to the real
        # instance
        def file_inside_clone(file, clone_location)
          return file if inside?(real_path(file), real_path(clone_location))

          raise "#{file} leads outside the instance clone (#{clone_location}); refusing to change it"
        end

        # Not Karaf. ConfigAdmin falls back to them, and they still name the real instance
        def remove_config_backups(clone_location)
          files_under(clone_location, "config").grep(/\.config\.bak\z/).each do |file|
            File.delete(file_inside_clone(file, clone_location))
          end
        end

        # Binary reads, since etc/ holds keystores
        def files_under(clone_location, *directories)
          files = directories.flat_map do |directory|
            base = File.join(clone_location, directory)
            Dir.glob("**/*", File::FNM_DOTMATCH, base:).map { |file| File.join(base, file) }
          end
          files.select { |file| File.file?(file) }
        end

        # The trailing "/" keeps a sibling that shares the path's prefix (/var/lib/openhab-old) from matching, and the
        # lookbehind keeps a longer path that ends with this one (/mnt/backup/var/lib/openhab) from being rewritten into
        # a path that doesn't exist. verify_isolation, which doesn't have the lookbehind, then stops the launch.
        def repoint_configs(location, clone_location)
          from = Regexp.new("(?<![\\w.+@%/-])#{Regexp.escape("#{location}/".b)}".b)
          to = "#{clone_location}/".b
          files_under(clone_location, "config").each do |file|
            contents = File.binread(file)
            repointed = contents.gsub(from) { to }
            File.binwrite(file_inside_clone(file, clone_location), repointed) unless repointed == contents
          end
        end

        # Added when it's missing, so that saving is off whichever way the distribution configures it. Every assignment
        # is turned off, since the last one wins when the properties are loaded. Binary, since a properties file is
        # Latin-1 as often as it is UTF-8. A key may be indented, and is followed by "=", ":" or only blanks, as in
        # Java properties.
        def disable_config_save(clone_location)
          file = "#{clone_location}/etc/config.properties"
          config_save = /^([ \t\f]*felix\.fileinstall\.enableConfigSave(?:[ \t\f]*[=:][ \t\f]*|[ \t\f]+))[^\r\n]*/
          properties = File.binread(file)
          disabled = if properties.match?(config_save)
                       properties.gsub(config_save, '\1false')
                     else
                       "#{properties.chomp}\nfelix.fileinstall.enableConfigSave = false\n"
                     end
          File.binwrite(file_inside_clone(file, clone_location), disabled) unless disabled == properties
        end

        def verify_isolation(location, clone_location)
          needle = "#{location}/".b
          leaks = files_under(clone_location, "config", "etc").select { |file| File.binread(file).include?(needle) }
          return if leaks.empty?

          raise "The instance clone still refers to #{location}, and could write to it. Files: #{leaks.join(", ")}"
        end
      end
    end
  end
end
