# frozen_string_literal: true

require "tmpdir"

RSpec.describe OpenHAB::RSpec::InstanceService do
  # The instance's name is in both paths, to check that the clone's path isn't filtered again
  let(:scratch) { File.realpath(Dir.mktmpdir("instance service spec")) }
  let(:root) { "#{scratch}/openhab root" }
  let(:clone_path) { "#{scratch}/openhab clone" }
  let(:instance_service) { described_class.new(nil) }

  def write(file, contents = "contents of #{File.basename(file)}")
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, contents)
  end

  def copy = instance_service.send(:copy, root, clone_path)

  def clone_files
    Dir.glob("**/*", File::FNM_DOTMATCH, base: clone_path).select { |file| File.file?("#{clone_path}/#{file}") }.sort
  end

  before { FileUtils.mkdir_p(root) }

  after do
    FileUtils.chmod_R(0o700, scratch)
    FileUtils.remove_entry(scratch)
  end

  describe "#copy" do
    it "copies files, including nested hidden ones, and makes the target if it doesn't exist" do
      write("#{root}/etc/custom.properties")
      write("#{root}/jsondb/.hidden.json")
      write("#{root}/uuid")

      copy

      expect(clone_files).to eq %w[etc/custom.properties jsondb/.hidden.json uuid]
      expect(File.read("#{clone_path}/uuid")).to eq "contents of uuid"
    end

    it "leaves out the cache, the contents of tmp and openhab-start-level, but keeps tmp itself" do
      write("#{root}/cache/bundle")
      write("#{root}/tmp/org.graalvm.python.vfsx123/file")
      write("#{root}/openhab-start-level")
      write("#{root}/uuid")

      copy

      expect(clone_files).to eq %w[uuid]
      expect(File.directory?("#{clone_path}/tmp")).to be true
    end

    it "copies a userdata directory that is named like an entry to skip" do
      root_bak = "#{scratch}/openhab.bak"
      write("#{root_bak}/uuid")

      instance_service.send(:copy, root_bak, clone_path)

      expect(clone_files).to eq %w[uuid]
    end

    it "leaves out any entry with instances or lib in its name, at any depth" do
      write("#{root}/uuid")
      write("#{root}/jsondb/library.json")
      write("#{root}/instances/instance.properties")
      write("#{root}/etc/my_instances.cfg")

      copy

      expect(clone_files).to eq %w[uuid]
    end

    it "makes tmp even when the userdata has none" do
      write("#{root}/uuid")

      copy

      expect(File.directory?("#{clone_path}/tmp")).to be true
    end

    it "leaves out the hidden entries of the userdata directory, which is a home directory for some installs" do
      write("#{root}/.cache/pnpm/metadata")
      write("#{root}/.ssh/id_ed25519")
      write("#{root}/.irb_history")
      write("#{root}/uuid")

      copy

      expect(clone_files).to eq %w[uuid]
    end

    it "leaves out what Karaf's own copy leaves out" do
      write("#{root}/lock")
      write("#{root}/cache.lock")
      write("#{root}/data/transaction_1.log")
      write("#{root}/data/bundle.instance")
      write("#{root}/instances/instance.properties")
      write("#{root}/uuid")

      copy

      expect(clone_files).to eq %w[uuid]
    end

    it "leaves out any backup, and keeps the files they back up" do
      write("#{root}/config/org/openhab/addons.config")
      write("#{root}/config/org/openhab/addons.config.bak")
      write("#{root}/config/profile.config.bak")
      write("#{root}/etc/org.example.cfg")
      write("#{root}/etc/org.example.cfg.bak")

      copy

      expect(clone_files).to eq %w[config/org/openhab/addons.config etc/org.example.cfg]
    end

    it "copies a symlinked file as an ordinary file" do
      write("#{scratch}/elsewhere/log4j2.xml", "<Configuration/>")
      FileUtils.mkdir_p("#{root}/etc")
      File.symlink("#{scratch}/elsewhere/log4j2.xml", "#{root}/etc/log4j2.xml")

      copy

      expect(File.symlink?("#{clone_path}/etc/log4j2.xml")).to be false
      expect(File.read("#{clone_path}/etc/log4j2.xml")).to eq "<Configuration/>"
    end

    it "doesn't touch what is already in the target" do
      write("#{clone_path}/instances/instance.properties", "count = 1\n")
      write("#{root}/instances/instance.properties", "count = 7\n")
      write("#{root}/uuid")

      copy

      expect(File.read("#{clone_path}/instances/instance.properties")).to eq "count = 1\n"
    end

    context "when something can't be read", skip: (Process.uid.zero? ? "root reads everything" : false) do
      it "skips a file, with a warning" do
        write("#{root}/jsondb/readable.json")
        write("#{root}/jsondb/secret.json")
        File.chmod(0o000, "#{root}/jsondb/secret.json")

        expect { copy }.to output(%r{Not cloning #{Regexp.escape(root)}/jsondb/secret.json}).to_stderr

        expect(clone_files).to eq %w[jsondb/readable.json]
      end

      it "skips a directory, with a warning" do
        write("#{root}/jsondb/readable.json")
        write("#{root}/private/file")
        File.chmod(0o000, "#{root}/private")

        expect { copy }.to output(%r{Not cloning #{Regexp.escape(root)}/private}).to_stderr

        expect(clone_files).to eq %w[jsondb/readable.json]
      end

      it "still makes tmp, which only has to exist" do
        write("#{root}/tmp/file")
        File.chmod(0o000, "#{root}/tmp")

        expect { copy }.not_to output.to_stderr

        expect(File.directory?("#{clone_path}/tmp")).to be true
      end

      it "raises when the userdata directory itself can't be read, since there would be no clone" do
        write("#{root}/uuid")
        File.chmod(0o000, root)

        expect { copy }.to raise_error(Errno::EACCES)
      end

      it "raises when the userdata directory can be listed but not searched, since nothing in it could be cloned" do
        write("#{root}/uuid")
        File.chmod(0o444, root)

        expect { copy }.to raise_error(Errno::EACCES)
      end
    end

    it "raises when the userdata directory isn't there" do
      expect { instance_service.send(:copy, "#{scratch}/missing", clone_path) }.to raise_error(Errno::ENOENT)
    end

    it "skips an entry that disappears while it is being copied, with a warning" do
      write("#{root}/gone.json")
      write("#{root}/uuid")
      allow(IO).to receive(:copy_stream).and_wrap_original do |original, from, *args|
        next original.call(from, *args) unless File.basename(from) == "gone.json"

        File.delete(from)
        raise Errno::ENOENT, from
      end

      expect { copy }.to output(%r{Not cloning #{Regexp.escape(root)}/gone.json}).to_stderr

      expect(clone_files).to eq %w[uuid]
    end

    it "doesn't leave half a file behind when the entry disappears part way through" do
      write("#{root}/broken.json")
      write("#{root}/uuid")
      allow(IO).to receive(:copy_stream).and_wrap_original do |original, from, to|
        next original.call(from, to) unless File.basename(from) == "broken.json"

        File.write(to, "half")
        File.delete(from)
        raise Errno::ENOENT, from
      end

      expect { copy }.to output(/Not cloning/).to_stderr

      expect(clone_files).to eq %w[uuid]
    end

    it "raises when the clone can't be written, instead of skipping the entry" do
      write("#{root}/uuid")
      allow(IO).to receive(:copy_stream).and_raise(Errno::ENOSPC)

      expect { copy }.to raise_error(Errno::ENOSPC)
    end

    it "raises, and doesn't call the entry gone, when a missing directory is on the clone's side" do
      write("#{root}/uuid")
      allow(IO).to receive(:copy_stream).and_raise(Errno::ENOTDIR)

      expect { copy }.to raise_error(Errno::ENOTDIR)
    end

    it "skips a pipe instead of waiting for a writer, with a warning" do
      write("#{root}/uuid")
      File.mkfifo("#{root}/pipe")

      expect { copy }.to output(%r{Not cloning #{Regexp.escape(root)}/pipe}).to_stderr

      expect(clone_files).to eq %w[uuid]
    end

    it "makes a read-only file writable in the clone, as Karaf's copy did" do
      write("#{root}/uuid")
      File.chmod(0o444, "#{root}/uuid")

      copy

      # Not File.writable?, which is true for root whatever the mode
      expect(File.stat("#{clone_path}/uuid").mode & 0o200).to eq 0o200
    end
  end

  describe "#filter_resource" do
    let(:props) { { "openhab".b => "rspec".b, root.b => clone_path.b } }

    def filter(path) = instance_service.send(:filter_resource, clone_path, path, props)

    it "makes the file name the clone instead of the instance it was copied from" do
      write("#{clone_path}/etc/custom.properties", "log = #{root}/logs/openhab.log\n")
      write("#{clone_path}/etc/system.properties", "name = openhab\nbase = #{root}\n")

      filter("etc/custom.properties")
      filter("etc/system.properties")

      expect(File.read("#{clone_path}/etc/custom.properties")).to eq "log = #{clone_path}/logs/rspec.log\n"
      expect(File.read("#{clone_path}/etc/system.properties")).to eq "name = rspec\nbase = #{clone_path}\n"
    end

    it "doesn't filter the clone's path again" do
      write("#{clone_path}/etc/custom.properties", "base = #{root} for openhab, not #{root}\n")

      filter("etc/custom.properties")

      expect(File.read("#{clone_path}/etc/custom.properties"))
        .to eq "base = #{clone_path} for rspec, not #{root}\n"
    end

    it "filters a file that isn't UTF-8, and leaves its other bytes as they were" do
      write("#{clone_path}/etc/custom.properties", "name = openhab caf\xE9\n".b)

      filter("etc/custom.properties")

      expect(File.binread("#{clone_path}/etc/custom.properties")).to eq "name = rspec caf\xE9\n".b
    end

    it "keeps the line endings the file has" do
      write("#{clone_path}/etc/custom.properties", "a = openhab\r\nb = openhab\n".b)

      filter("etc/custom.properties")

      expect(File.binread("#{clone_path}/etc/custom.properties")).to eq "a = rspec\r\nb = rspec\n".b
    end

    it "leaves no backup behind" do
      write("#{clone_path}/etc/custom.properties", "name = openhab\n")

      filter("etc/custom.properties")

      expect(Dir.children("#{clone_path}/etc")).to eq %w[custom.properties]
    end

    it "does nothing for a file that isn't there" do
      FileUtils.mkdir_p("#{clone_path}/etc")

      expect { filter("etc/custom.properties") }.not_to raise_error

      expect(Dir.children("#{clone_path}/etc")).to be_empty
    end
  end

  describe "#fill_management_config" do
    def fill = instance_service.send(:fill_management_config, clone_path)

    it "fills in an empty management config" do
      write("#{clone_path}/etc/org.apache.karaf.management.cfg", "")

      fill

      expect(File.read("#{clone_path}/etc/org.apache.karaf.management.cfg")).to include "rmiRegistryPort = 1099"
    end

    it "leaves a config that has contents alone" do
      write("#{clone_path}/etc/org.apache.karaf.management.cfg", "rmiRegistryPort = 2000\n")

      fill

      expect(File.read("#{clone_path}/etc/org.apache.karaf.management.cfg")).to eq "rmiRegistryPort = 2000\n"
    end

    it "does nothing when there is no management config" do
      expect { fill }.not_to raise_error
    end
  end

  describe "#clone_instance" do
    let(:karaf) { OpenHAB::RSpec::Karaf.new(clone_path) }
    let(:karaf_service) { org.apache.karaf.instance.core.internal.InstanceServiceImpl.new }

    # When the suite has already launched openHAB, JRuby's loaders include the harness's own, which are Ruby objects
    # without #class_loader. Always have one, that finds nothing, so this doesn't depend on what ran before. The Java
    # classes are looked up first: JRuby asks every loader to find a class it doesn't know yet, this one included.
    let(:bundle_loader) do
      not_found = java.lang.ClassNotFoundException
      no_resources = java.util.Collections.empty_enumeration
      bundle = Object.new
      bundle.define_singleton_method(:get_resource) { |_path| nil }
      bundle.define_singleton_method(:get_resources) { |_path| no_resources }
      bundle.define_singleton_method(:load_class) do |name|
        error = not_found.new(name)
        raise error
      end
      OpenHAB::RSpec::JRuby::OSGiBundleClassLoader.new(bundle)
    end

    def clone_instance(name = "openhab") = described_class.new(karaf_service).clone_instance(name, "rspec", clone_path)

    around do |example|
      previous = %w[karaf.instances karaf.etc].to_h { |name| [name, java.lang.System.get_property(name)] }
      example.run
    ensure
      previous.each do |name, value|
        java.lang.System.clear_property(name)
        java.lang.System.set_property(name, value) if value
      end
    end

    before do
      JRuby.runtime.instance_config.add_loader(bundle_loader)
      write("#{clone_path}/instances/instance.properties", <<~TEXT)
        count = 1
        item.0.name = openhab
        item.0.loc = #{root}
        item.0.pid = 7263
        item.0.root = true
      TEXT
      # Karaf reads the default ports from these, and logs a stack trace at debug level when it can't
      write("#{clone_path}/etc/org.apache.karaf.shell.cfg", "sshPort = 8101\n")
      write("#{clone_path}/etc/org.apache.karaf.management.cfg", "rmiRegistryPort = 1099\nrmiServerPort = 44444\n")
      java.lang.System.set_property("karaf.instances", "#{clone_path}/instances")
      java.lang.System.set_property("karaf.etc", "#{clone_path}/etc")
      karaf.send(:load_boot_jars)
      karaf.send(:find_karaf_instance_jar)
    end

    after do
      extra_loaders = JRuby.runtime.instance_config.extra_loaders
      extra_loaders.remove(bundle_loader)
      karaf_loader = karaf.instance_variable_get(:@karaf_instance_loader)
      extra_loaders.remove(extra_loaders.find { |l| l.respond_to?(:class_loader) && l.class_loader == karaf_loader })
    end

    it "copies the instance, makes the copy name itself, and adds it to the instance list, where Karaf finds it" do
      write("#{root}/uuid")
      write("#{root}/etc/custom.properties", "log = #{root}/logs/openhab.log\n")

      clone_instance

      expect(File.read("#{clone_path}/uuid")).to eq "contents of uuid"
      expect(File.read("#{clone_path}/etc/custom.properties")).to eq "log = #{clone_path}/logs/rspec.log\n"
      fresh_service = org.apache.karaf.instance.core.internal.InstanceServiceImpl.new
      expect(fresh_service.instances.map(&:name)).to eq %w[openhab rspec]
      expect(fresh_service.get_instance("openhab")).to be_root
      expect(fresh_service.get_instance("openhab").location).to eq root
      expect(fresh_service.get_instance("rspec")).not_to be_root
      expect(fresh_service.get_instance("rspec").location).to eq clone_path
    end

    it "makes each of the files Karaf filters name the clone" do
      files = %w[etc/custom.properties
                 etc/org.apache.karaf.management.cfg
                 etc/org.apache.karaf.shell.cfg
                 etc/system.properties
                 bin/karaf
                 bin/start
                 bin/stop
                 bin/karaf.bat
                 bin/start.bat
                 bin/stop.bat]
      files.each { |file| write("#{root}/#{file}", "path = #{root}\nname = openhab\n") }

      clone_instance

      files.each do |file|
        expect(File.read("#{clone_path}/#{file}")).to eq("path = #{clone_path}\nname = rspec\n"), file
      end
    end

    it "fills in an empty management config before the clone is registered" do
      write("#{root}/etc/org.apache.karaf.management.cfg", "")

      clone_instance

      expect(File.read("#{clone_path}/etc/org.apache.karaf.management.cfg")).to include "rmiRegistryPort = 1099"
    end

    it "doesn't register the clone when it can't be finished" do
      write("#{root}/etc/org.apache.karaf.management.cfg", "")
      allow(File).to receive(:write).and_call_original
      allow(File).to receive(:write).with(/org\.apache\.karaf\.management\.cfg\z/, anything).and_raise(Errno::ENOSPC)

      expect { clone_instance }.to raise_error(Errno::ENOSPC)

      fresh_service = org.apache.karaf.instance.core.internal.InstanceServiceImpl.new
      expect(fresh_service.get_instance("rspec")).to be_nil
    end

    it "refuses to clone an instance that has been cloned" do
      clone_instance

      expect { clone_instance }.to raise_error(ArgumentError, /Instance rspec already exists/)
    end

    it "refuses to clone an instance that isn't there" do
      expect { clone_instance("missing") }.to raise_error(ArgumentError, /Instance missing not found/)
    end
  end
end
