# frozen_string_literal: true

require "tmpdir"

RSpec.describe OpenHAB::RSpec::Karaf do
  # The instance's name is in both paths, to check that the clone's path isn't filtered again
  let(:scratch) { File.realpath(Dir.mktmpdir("karaf clone spec")) }
  let(:root) { "#{scratch}/openhab root" }
  let(:clone_path) { "#{scratch}/openhab clone" }
  let(:karaf) { described_class.new(clone_path) }

  def write(file, contents = "contents of #{File.basename(file)}")
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, contents)
  end

  def copy = karaf.send(:copy_instance, root, clone_path)

  def clone_files
    Dir.glob("**/*", File::FNM_DOTMATCH, base: clone_path).select { |file| File.file?("#{clone_path}/#{file}") }.sort
  end

  before { FileUtils.mkdir_p(root) }

  after do
    FileUtils.chmod_R(0o700, scratch)
    FileUtils.remove_entry(scratch)
  end

  describe "#find_jar_version" do
    it "finds the newest version even when the directory's path contains a dash" do
      FileUtils.mkdir_p("#{scratch}/open-hab/boot")
      FileUtils.touch(["#{scratch}/open-hab/boot/org.apache.karaf.main-4.4.11.jar",
                       "#{scratch}/open-hab/boot/org.apache.karaf.main-4.4.12.jar",
                       "#{scratch}/open-hab/boot/org.apache.karaf.other-5.0.0.jar"])

      expect(karaf.send(:find_jar_version, "#{scratch}/open-hab/boot", "org.apache.karaf.main")).to eq "4.4.12"
    end
  end

  describe "#copy_instance" do
    it "copies files, including nested hidden ones, and makes the target if it doesn't exist" do
      write("#{root}/etc/custom.properties")
      write("#{root}/jsondb/.hidden.json")
      write("#{root}/uuid")

      copy

      expect(clone_files).to eq %w[etc/custom.properties jsondb/.hidden.json uuid]
      expect(File.read("#{clone_path}/uuid")).to eq "contents of uuid"
    end

    it "leaves out what the harness deletes from the clone anyway, but keeps tmp itself" do
      write("#{root}/cache/bundle")
      write("#{root}/tmp/org.graalvm.python.vfsx123/file")
      write("#{root}/openhab-start-level")
      write("#{root}/uuid")

      copy

      expect(clone_files).to eq %w[uuid]
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
    end

    it "skips an entry that disappears while it is being copied, with a warning" do
      write("#{root}/gone.json")
      write("#{root}/uuid")
      allow(IO).to receive(:copy_stream).and_wrap_original do |original, from, *args|
        raise Errno::ENOENT, from if File.basename(from) == "gone.json"

        original.call(from, *args)
      end

      expect { copy }.to output(%r{Not cloning #{Regexp.escape(root)}/gone.json}).to_stderr

      expect(clone_files).to eq %w[uuid]
    end

    it "doesn't leave half a file behind when copying it fails" do
      write("#{root}/broken.json")
      write("#{root}/uuid")
      allow(IO).to receive(:copy_stream).and_wrap_original do |original, from, to|
        next original.call(from, to) unless File.basename(from) == "broken.json"

        File.write(to, "half")
        raise Errno::EIO, from
      end

      expect { copy }.to output(/Not cloning/).to_stderr

      expect(clone_files).to eq %w[uuid]
    end

    it "makes a read-only file writable in the clone, as Karaf's copy did" do
      write("#{root}/uuid")
      File.chmod(0o444, "#{root}/uuid")

      copy

      expect(File.writable?("#{clone_path}/uuid")).to be true
    end
  end

  describe "#filter_clone_files" do
    def filter = karaf.send(:filter_clone_files, "openhab", root)

    it "makes the files name the clone instead of the instance it was copied from" do
      write("#{clone_path}/etc/custom.properties", "log = #{root}/logs/openhab.log\n")
      write("#{clone_path}/etc/system.properties", "name = openhab\nbase = #{root}\n")

      filter

      expect(File.read("#{clone_path}/etc/custom.properties")).to eq "log = #{clone_path}/logs/rspec.log\n"
      expect(File.read("#{clone_path}/etc/system.properties")).to eq "name = rspec\nbase = #{clone_path}\n"
    end

    it "doesn't filter the clone's path again" do
      write("#{clone_path}/etc/custom.properties", "base = #{root} for openhab, not #{root}\n")

      filter

      expect(File.read("#{clone_path}/etc/custom.properties"))
        .to eq "base = #{clone_path} for rspec, not #{root}\n"
    end

    it "filters a file that isn't UTF-8, and leaves its other bytes as they were" do
      write("#{clone_path}/etc/custom.properties", "name = openhab caf\xE9\n".b)

      filter

      expect(File.binread("#{clone_path}/etc/custom.properties")).to eq "name = rspec caf\xE9\n".b
    end

    it "leaves other files, and files that aren't there, alone" do
      write("#{clone_path}/etc/other.cfg", "name = openhab\n")

      expect { filter }.not_to(change { File.read("#{clone_path}/etc/other.cfg") })
    end
  end

  describe "#fix_rmi_registry_npe" do
    it "fills in an empty management config in the clone" do
      write("#{clone_path}/etc/org.apache.karaf.management.cfg", "")

      karaf.send(:fix_rmi_registry_npe)

      expect(File.read("#{clone_path}/etc/org.apache.karaf.management.cfg")).to include "rmiRegistryPort = 1099"
    end

    it "leaves a config that has contents alone" do
      write("#{clone_path}/etc/org.apache.karaf.management.cfg", "rmiRegistryPort = 2000\n")

      karaf.send(:fix_rmi_registry_npe)

      expect(File.read("#{clone_path}/etc/org.apache.karaf.management.cfg")).to eq "rmiRegistryPort = 2000\n"
    end

    it "does nothing when the clone has no management config" do
      expect { karaf.send(:fix_rmi_registry_npe) }.not_to raise_error
    end
  end

  describe "#register_clone" do
    around do |example|
      previous = %w[karaf.instances karaf.etc].to_h { |name| [name, java.lang.System.get_property(name)] }
      example.run
    ensure
      previous.each do |name, value|
        java.lang.System.clear_property(name)
        java.lang.System.set_property(name, value) if value
      end
    end

    after do
      extra_loaders = JRuby.runtime.instance_config.extra_loaders
      loader = extra_loaders.find { |l| l.class_loader == karaf.instance_variable_get(:@karaf_instance_loader) }
      extra_loaders.remove(loader)
    end

    it "adds the clone to the instance list, where Karaf itself finds it" do
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

      karaf.send(:register_clone)

      service = org.apache.karaf.instance.core.internal.InstanceServiceImpl.new
      expect(service.instances.map(&:name)).to eq %w[openhab rspec]
      expect(service.get_instance("openhab")).to be_root
      expect(service.get_instance("openhab").location).to eq root
      expect(service.get_instance("rspec")).not_to be_root
      expect(service.get_instance("rspec").location).to eq clone_path
    end
  end
end
