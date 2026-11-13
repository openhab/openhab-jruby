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

  describe "#real_path" do
    def real_path(path) = described_class.send(:real_path, path)

    before do
      FileUtils.mkdir_p("#{scratch}/real/child")
      File.symlink("#{scratch}/real/child", "#{scratch}/link")
    end

    it "follows a symlink before it collapses .." do
      expect(real_path("#{scratch}/link/..")).to eq "#{scratch}/real"
    end

    it "collapses .. in the part that doesn't exist yet only after it has resolved what does" do
      expect(real_path("#{scratch}/link/../new/dir")).to eq "#{scratch}/real/new/dir"
      expect(real_path("#{scratch}/link/../new/../other")).to eq "#{scratch}/real/other"
    end

    it "names the path when part of it can't be resolved" do
      write("#{scratch}/file")
      path = "#{scratch}/file/clone"

      expect { real_path(path) }.to raise_error(ArgumentError, /Can't resolve #{Regexp.escape(path)}/)
    end
  end

  describe "#isolate_clone" do
    let(:config_dir) { "#{clone_path}/config/org/openhab" }

    def isolate(location = root) = described_class.isolate_clone(location, clone_path)

    def clone_contents
      Dir.glob("#{clone_path}/**/*").select { |file| File.file?(file) }.to_h { |file| [file, File.read(file)] }
    end

    before do
      FileUtils.mkdir_p(config_dir)
      write("#{clone_path}/etc/config.properties", "felix.fileinstall.enableConfigSave = true\n")
    end

    it "repoints the real path at the clone in the config store" do
      write("#{config_dir}/addons.config", <<~TEXT)
        a="file:#{root}/etc/org.openhab.addons.cfg"
        b="file://#{root}/etc/org.openhab.persistence.cfg"
        c="#{root}/etc/org.openhab.ephemeris.cfg"
      TEXT

      isolate

      expect(File.read("#{config_dir}/addons.config")).to eq(<<~TEXT)
        a="file:#{clone_path}/etc/org.openhab.addons.cfg"
        b="file://#{clone_path}/etc/org.openhab.persistence.cfg"
        c="#{clone_path}/etc/org.openhab.ephemeris.cfg"
      TEXT
    end

    it "leaves a sibling directory that shares the real path's prefix alone" do
      siblings = <<~TEXT
        a="file:#{root}-old/etc/org.openhab.addons.cfg"
        b="file:#{root}2/etc/org.openhab.addons.cfg"
        c="file:#{root}+backup/etc/org.openhab.addons.cfg"
        d="file:#{root}@home/etc/org.openhab.addons.cfg"
      TEXT
      write("#{config_dir}/addons.config", siblings)

      expect { isolate }.not_to raise_error

      expect(File.read("#{config_dir}/addons.config")).to eq(siblings)
    end

    it "leaves a longer path that ends with the real path alone, since it isn't the real instance" do
      longer = %(a="file:/mnt/backup#{root}/etc/org.openhab.addons.cfg"\n)
      write("#{config_dir}/addons.config", longer)

      expect { isolate }.not_to raise_error

      expect(File.read("#{config_dir}/addons.config")).to eq(longer)
    end

    it "doesn't rewrite the real path where a space precedes it, and stops instead" do
      ambiguous = %(a="file:/mnt/backup #{root}/etc/org.openhab.addons.cfg"\n)
      write("#{config_dir}/addons.config", ambiguous)

      expect { isolate }.to raise_error(/still refers to #{Regexp.escape(root)}.*addons\.config/)

      expect(File.read("#{config_dir}/addons.config")).to eq(ambiguous)
    end

    it "doesn't take the clone's own path for the real one when it is under a directory named like it" do
      clone = "#{scratch}/home#{root}/clone"
      write("#{clone}/etc/config.properties", "felix.fileinstall.enableConfigSave = true\n")
      write("#{clone}/config/addons.config", %(a="file:#{clone}/etc/org.openhab.addons.cfg"\n))

      expect { described_class.isolate_clone(root, clone) }.not_to raise_error

      expect(File.read("#{clone}/config/addons.config")).to eq(%(a="file:#{clone}/etc/org.openhab.addons.cfg"\n))
    end

    it "repoints the path the store spells the way the real instance resolves, given a symlink to it" do
      FileUtils.mkdir_p(root)
      File.symlink(root, "#{scratch}/link")
      write("#{config_dir}/addons.config", %(a="file:#{root}/etc/org.openhab.addons.cfg"\n))

      isolate("#{scratch}/link")

      expect(File.read("#{config_dir}/addons.config")).to eq(%(a="file:#{clone_path}/etc/org.openhab.addons.cfg"\n))
    end

    it "repoints the real path when it is given with a trailing slash" do
      write("#{config_dir}/addons.config", %(a="file:#{root}/etc/org.openhab.addons.cfg"\n))

      isolate("#{root}/")

      expect(File.read("#{config_dir}/addons.config")).to eq(%(a="file:#{clone_path}/etc/org.openhab.addons.cfg"\n))
    end

    it "removes the config backups and keeps the configs" do
      write("#{config_dir}/addons.config", "a=1\n")
      write("#{config_dir}/addons.config.bak", %(a="file:#{root}/etc/org.openhab.addons.cfg"\n))

      isolate

      expect(Dir.children(config_dir)).to eq(["addons.config"])
    end

    it "refuses a clone that is inside the instance it was cloned from" do
      FileUtils.mkdir_p("#{root}/nested-clone")

      expect { described_class.isolate_clone(root, "#{root}/nested-clone") }
        .to raise_error(ArgumentError, /instance it was cloned from.*or inside it/)
    end

    it "refuses a clone that is the instance it was cloned from, and changes nothing in it" do
      write("#{root}/config.bak", "a=1\n")

      expect { described_class.isolate_clone(root, root) }.to raise_error(ArgumentError, /instance it was cloned from/)

      expect(File.exist?("#{root}/config.bak")).to be(true)
    end

    it "refuses a clone that contains the instance it was cloned from, and changes nothing in it" do
      inside = "#{clone_path}/config/real-userdata"
      write("#{inside}/config/org/openhab/addons.config.bak", "a=1\n")
      write("#{inside}/etc/config.properties", "felix.fileinstall.enableConfigSave = true\n")

      expect { described_class.isolate_clone(inside, clone_path) }.to raise_error(ArgumentError, /or contains it/)

      expect(File.exist?("#{inside}/config/org/openhab/addons.config.bak")).to be(true)
      expect(File.read("#{inside}/etc/config.properties")).to eq("felix.fileinstall.enableConfigSave = true\n")
    end

    it "repoints a clone path with backslashes in it literally" do
      backslashed = "#{scratch}/clone\\0dir"
      write("#{backslashed}/etc/config.properties", "felix.fileinstall.enableConfigSave = true\n")
      write("#{backslashed}/config/addons.config", %(a="file:#{root}/etc/x.cfg"\n))

      described_class.isolate_clone(root, backslashed)

      expect(File.read("#{backslashed}/config/addons.config")).to eq(%(a="file:#{backslashed}/etc/x.cfg"\n))
    end

    it "changes nothing when it runs again on a clone it has already isolated" do
      write("#{config_dir}/addons.config", %(a="file:#{root}/etc/org.openhab.addons.cfg"\n))
      isolate

      expect { isolate }.not_to(change { clone_contents })
    end

    it "turns off fileinstall's config saving" do
      isolate

      expect(File.read("#{clone_path}/etc/config.properties")).to eq("felix.fileinstall.enableConfigSave = false\n")
    end

    it "turns off the setting when its line has trailing whitespace and CRLF line endings" do
      write("#{clone_path}/etc/config.properties",
            "felix.fileinstall.enableConfigSave = true  \r\nkaraf.shutdown.port = -1\r\n")

      isolate

      expect(File.read("#{clone_path}/etc/config.properties"))
        .to eq("felix.fileinstall.enableConfigSave = false\r\nkaraf.shutdown.port = -1\r\n")
    end

    it "turns off an indented setting instead of adding a second one" do
      write("#{clone_path}/etc/config.properties", "  felix.fileinstall.enableConfigSave = true\n")

      isolate

      expect(File.read("#{clone_path}/etc/config.properties")).to eq("  felix.fileinstall.enableConfigSave = false\n")
    end

    it "turns off every assignment of the setting, so a later one can't turn it back on" do
      write("#{clone_path}/etc/config.properties", <<~TEXT)
        felix.fileinstall.enableConfigSave = true
        #felix.fileinstall.enableConfigSave = true
        karaf.shutdown.port = -1
          felix.fileinstall.enableConfigSave = true
      TEXT

      isolate

      expect(File.read("#{clone_path}/etc/config.properties")).to eq(<<~TEXT)
        felix.fileinstall.enableConfigSave = false
        #felix.fileinstall.enableConfigSave = true
        karaf.shutdown.port = -1
          felix.fileinstall.enableConfigSave = false
      TEXT
    end

    it "turns off every assignment however it separates the key from the value" do
      write("#{clone_path}/etc/config.properties", <<~TEXT)
        felix.fileinstall.enableConfigSave = true
        felix.fileinstall.enableConfigSave: true
        felix.fileinstall.enableConfigSave true
        felix.fileinstall.enableConfigSave\t=\ttrue
        felix.fileinstall.enableConfigSaveOther = true
      TEXT

      isolate

      expect(File.read("#{clone_path}/etc/config.properties")).to eq(<<~TEXT)
        felix.fileinstall.enableConfigSave = false
        felix.fileinstall.enableConfigSave: false
        felix.fileinstall.enableConfigSave false
        felix.fileinstall.enableConfigSave\t=\tfalse
        felix.fileinstall.enableConfigSaveOther = true
      TEXT
    end

    it "turns off the setting in custom.properties, which is loaded after config.properties and wins" do
      write("#{clone_path}/etc/custom.properties", "log = 1\nfelix.fileinstall.enableConfigSave = true\n")

      isolate

      expect(File.read("#{clone_path}/etc/custom.properties"))
        .to eq("log = 1\nfelix.fileinstall.enableConfigSave = false\n")
      expect(File.read("#{clone_path}/etc/config.properties")).to eq("felix.fileinstall.enableConfigSave = false\n")
    end

    it "doesn't add the setting to a custom.properties that has none, or make one that isn't there" do
      write("#{clone_path}/etc/custom.properties", "log = 1\n")

      isolate

      expect(File.read("#{clone_path}/etc/custom.properties")).to eq("log = 1\n")
      FileUtils.rm("#{clone_path}/etc/custom.properties")
      isolate
      expect(File.exist?("#{clone_path}/etc/custom.properties")).to be(false)
    end

    it "keeps the bytes of a config.properties that isn't UTF-8" do
      File.binwrite("#{clone_path}/etc/config.properties",
                    "# caf\xE9\nfelix.fileinstall.enableConfigSave = true\n".b)

      isolate

      expect(File.binread("#{clone_path}/etc/config.properties"))
        .to eq("# caf\xE9\nfelix.fileinstall.enableConfigSave = false\n".b)
    end

    it "adds the setting when there is none to turn off" do
      write("#{clone_path}/etc/config.properties", "karaf.shutdown.port = -1\n")

      isolate

      expect(File.read("#{clone_path}/etc/config.properties")).to eq(<<~TEXT)
        karaf.shutdown.port = -1
        felix.fileinstall.enableConfigSave = false
      TEXT
    end

    it "raises when a file in etc/ still names the real instance" do
      write("#{clone_path}/etc/custom.properties", "jetty.keystore.path=#{root}/etc/keystore\n")

      expect { isolate }.to raise_error(/still refers to #{Regexp.escape(root)}.*custom\.properties/)
    end

    it "raises when a file in etc/ names the real instance as a file:/// URL" do
      write("#{clone_path}/etc/other.properties", %(keystore = "file://#{root}/etc/keystore"\n))

      expect { isolate }.to raise_error(/still refers to #{Regexp.escape(root)}.*other\.properties/)
    end

    context "with a symlink in the clone" do
      let(:outside) { "#{scratch}/outside" }

      before { FileUtils.mkdir_p(outside) }

      it "doesn't write through a symlinked config file" do
        original = %(a="file:#{root}/etc/org.openhab.addons.cfg"\n)
        write("#{outside}/addons.config", original)
        File.symlink("#{outside}/addons.config", "#{config_dir}/addons.config")

        expect { isolate }.to raise_error(/symlinks in its config store.*addons\.config/)

        expect(File.read("#{outside}/addons.config")).to eq(original)
      end

      it "doesn't write or delete through a symlinked directory inside the config store" do
        original = %(a="file:#{root}/etc/org.openhab.addons.cfg"\n)
        write("#{outside}/addons.config", original)
        write("#{outside}/addons.config.bak", original)
        File.symlink(outside, "#{config_dir}/linked")

        expect { isolate }.to raise_error(/symlinks in its config store.*linked/)

        expect(Dir.children(outside)).to contain_exactly("addons.config", "addons.config.bak")
        expect(File.read("#{outside}/addons.config")).to eq(original)
      end

      it "doesn't leave a dangling symlink for something to create the target of" do
        File.symlink("#{outside}/new.config", "#{config_dir}/new.config")

        expect { isolate }.to raise_error(/symlinks in its config store.*new\.config/)

        expect(File.exist?("#{outside}/new.config")).to be(false)
      end

      it "refuses a symlink in the config store even when it leads inside the clone" do
        write("#{clone_path}/etc/addons.config", "a=1\n")
        File.symlink("#{clone_path}/etc/addons.config", "#{config_dir}/addons.config")

        expect { isolate }.to raise_error(/symlinks in its config store/)
      end

      it "doesn't write or delete through a symlinked config directory" do
        original = %(a="file:#{root}/etc/org.openhab.addons.cfg"\n)
        write("#{outside}/addons.config", original)
        write("#{outside}/addons.config.bak", original)
        FileUtils.rm_rf("#{clone_path}/config")
        File.symlink(outside, "#{clone_path}/config")

        expect { isolate }.to raise_error(/symlinks in its config store/)

        expect(Dir.children(outside)).to contain_exactly("addons.config", "addons.config.bak")
        expect(File.read("#{outside}/addons.config")).to eq(original)
      end

      it "doesn't write through a symlinked custom.properties" do
        original = "felix.fileinstall.enableConfigSave = true\n"
        write("#{outside}/custom.properties", original)
        File.symlink("#{outside}/custom.properties", "#{clone_path}/etc/custom.properties")

        expect { isolate }.to raise_error(/leads outside the instance clone/)

        expect(File.read("#{outside}/custom.properties")).to eq(original)
      end

      it "doesn't write through a symlinked config.properties" do
        original = "felix.fileinstall.enableConfigSave = true\n"
        write("#{outside}/config.properties", original)
        File.delete("#{clone_path}/etc/config.properties")
        File.symlink("#{outside}/config.properties", "#{clone_path}/etc/config.properties")

        expect { isolate }.to raise_error(/leads outside the instance clone/)

        expect(File.read("#{outside}/config.properties")).to eq(original)
      end
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

    def clone_instance(name = "openhab", to: clone_path)
      described_class.new(karaf_service).clone_instance(name, "rspec", to)
    end

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
      write("#{root}/etc/config.properties", "felix.fileinstall.enableConfigSave = true\n")
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

    it "makes a clone that refers only to itself" do
      write("#{root}/config/org/openhab/addons.config", %(a="file:#{root}/etc/org.openhab.addons.cfg"\n))
      write("#{root}/config/org/openhab/addons.config.bak", %(a="file:#{root}/etc/org.openhab.addons.cfg"\n))

      clone_instance

      expect(Dir.children("#{clone_path}/config/org/openhab")).to eq(["addons.config"])
      expect(File.read("#{clone_path}/config/org/openhab/addons.config"))
        .to eq(%(a="file:#{clone_path}/etc/org.openhab.addons.cfg"\n))
      expect(File.read("#{clone_path}/etc/config.properties")).to eq("felix.fileinstall.enableConfigSave = false\n")
    end

    it "doesn't register a clone that still refers to the instance it was cloned from" do
      write("#{root}/etc/other.properties", "keystore = #{root}/etc/keystore\n")

      expect { clone_instance }.to raise_error(/still refers to #{Regexp.escape(root)}.*other\.properties/)

      fresh_service = org.apache.karaf.instance.core.internal.InstanceServiceImpl.new
      expect(fresh_service.get_instance("rspec")).to be_nil
    end

    it "refuses a clone that is the instance it was cloned from before it copies anything" do
      write("#{root}/uuid")

      expect { clone_instance(to: root) }.to raise_error(ArgumentError, /instance it was cloned from/)

      expect(File.read("#{root}/uuid")).to eq "contents of uuid"
    end

    it "refuses a clone that doesn't exist yet but would be inside the instance it was cloned from" do
      write("#{root}/uuid")

      expect { clone_instance(to: "#{root}/not yet/clone") }.to raise_error(ArgumentError, /or inside it/)

      expect(Dir.children(root)).to contain_exactly("uuid", "etc")
    end

    it "refuses a clone that contains the instance it was cloned from before it copies anything" do
      write("#{root}/uuid")

      expect { clone_instance(to: scratch) }.to raise_error(ArgumentError, /or contains it/)

      expect(File.read("#{root}/uuid")).to eq "contents of uuid"
      expect(File.exist?("#{scratch}/etc")).to be(false)
    end

    context "with a clone path that reaches the instance through a symlink and .." do
      before do
        write("#{root}/child/file")
        File.symlink("#{root}/child", "#{scratch}/link")
      end

      it "refuses a clone that is the instance before it copies anything" do
        write("#{root}/uuid")

        expect { clone_instance(to: "#{scratch}/link/..") }.to raise_error(ArgumentError, /instance it was cloned from/)

        expect(File.read("#{root}/uuid")).to eq "contents of uuid"
        fresh_service = org.apache.karaf.instance.core.internal.InstanceServiceImpl.new
        expect(fresh_service.get_instance("rspec")).to be_nil
      end

      it "refuses a clone that doesn't exist yet but would be inside the instance" do
        expect { clone_instance(to: "#{scratch}/link/../clone") }.to raise_error(ArgumentError, /or inside it/)

        expect(File.exist?("#{root}/clone")).to be(false)
      end
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
