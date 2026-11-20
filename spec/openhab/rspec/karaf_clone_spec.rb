# frozen_string_literal: true

require "tmpdir"
require "pathname"

RSpec.describe OpenHAB::RSpec::Karaf do
  let(:scratch) { File.realpath(Dir.mktmpdir("karaf clone spec")) }
  let(:clone_path) { "#{scratch}/openhab clone" }
  let(:karaf) { described_class.new(clone_path) }

  def write(file, contents = "contents of #{File.basename(file)}")
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, contents)
  end

  after { FileUtils.remove_entry(scratch) }

  describe "#initialize" do
    it "defaults to .karaf in the current working directory" do
      expect(described_class.new.path).to eq File.join(Dir.pwd, ".karaf")
    end

    it "uses the default path when explicitly passed nil" do
      expect(described_class.new(nil).path).to eq File.join(Dir.pwd, ".karaf")
    end

    it "preserves an explicit path" do
      expect(karaf.path).to eq clone_path
    end

    it "makes a relative path absolute" do
      expect(described_class.new(".karaf-worker-1").path).to eq "#{Dir.pwd}/.karaf-worker-1"
    end

    it "preserves .. after a symlink when making the path absolute" do
      FileUtils.mkdir_p("#{scratch}/actual/child")
      File.symlink("#{scratch}/actual/child", "#{scratch}/link")
      relative = "#{Pathname.new(scratch).relative_path_from(Pathname.pwd)}/link/../clone"

      path = described_class.new(relative).path

      expect(path).to end_with("/link/../clone")
      expect(OpenHAB::RSpec::InstanceService.send(:real_path, path)).to eq "#{scratch}/actual/clone"
    end
  end

  describe "#prepare" do
    let(:userdata) { "#{scratch}/userdata" }
    let(:registered_root) { "#{scratch}/registered root" }

    def register_root(location)
      write("#{userdata}/tmp/instances/instance.properties", <<~TEXT)
        count = 1
        item.0.name = openhab
        item.0.loc = #{location}
        item.0.pid = 0
        item.0.root = true
      TEXT
    end

    around do |example|
      conf = ENV.fetch("OPENHAB_CONF", nil)
      properties = %w[karaf.data karaf.instances karaf.etc openhab.conf].to_h do |key|
        [key, java.lang.System.get_property(key)]
      end
      example.run
    ensure
      conf ? ENV["OPENHAB_CONF"] = conf : ENV.delete("OPENHAB_CONF")
      properties.each do |key, value|
        value ? java.lang.System.set_property(key, value) : java.lang.System.clear_property(key)
      end
    end

    before do
      %i[set_env set_java_properties set_java_properties_from_env].each do |step|
        allow(karaf).to receive(step)
      end
      allow(karaf).to receive_messages(oh_userdata: userdata, oh_conf: "#{scratch}/live-conf")
      java.lang.System.set_property("karaf.data", userdata)
      java.lang.System.set_property("karaf.etc", "#{registered_root}/etc")
      register_root(registered_root)
      write("#{registered_root}/etc/config.properties", "felix.fileinstall.enableConfigSave = false\n")
      write("#{registered_root}/etc/org.apache.karaf.shell.cfg", "sshPort = 8101\n")
      write("#{registered_root}/etc/org.apache.karaf.management.cfg", "rmiRegistryPort = 1099\nrmiServerPort = 44444\n")
      write("#{registered_root}/uuid", "rebuilt")
    end

    it "removes the entire old clone before rebuilding without starting the runtime" do
      write("#{clone_path}/old/file")
      expect(karaf).not_to receive(:start_instance)

      karaf.prepare(rebuild: true)

      expect(File.exist?("#{clone_path}/old")).to be false
      expect(File.read("#{clone_path}/uuid")).to eq "rebuilt"
    end

    it "refuses to delete a clone that contains the root instance" do
      write("#{clone_path}/root/uuid", "keep me")
      allow(karaf).to receive(:oh_userdata).and_return("#{clone_path}/root")

      expect { karaf.prepare(rebuild: true) }.to raise_error(ArgumentError, /contains it/)
      expect(File.read("#{clone_path}/root/uuid")).to eq "keep me"
    end

    it "refuses to rebuild the root instance" do
      karaf.use_root_instance = true

      expect { karaf.prepare(rebuild: true) }.to raise_error(ArgumentError, "Cannot rebuild the root instance")
    end

    %i[same
       inside
       contains
       symlink
       symlink_parent].product(%i[oh_home oh_runtime oh_conf oh_userdata]) do |overlap, location|
      it "protects #{location} when the clone is #{overlap} before writing clone files" do
        live = "#{scratch}/live"
        write("#{live}/keep", "keep me")
        target = case overlap
                 when :same then live
                 when :inside then "#{live}/clone"
                 when :contains then scratch
                 when :symlink
                   File.symlink(live, "#{scratch}/alias")
                   "#{scratch}/alias"
                 when :symlink_parent
                   File.symlink(live, "#{scratch}/alias")
                   "#{scratch}/alias/new/clone"
                 end
        allow(karaf).to receive(:path).and_return(target)
        allow(karaf).to receive(location).and_return(live)
        allow(karaf).to receive(:load_boot_jars)
        karaf.private_confdir = true
        expect(karaf).not_to receive(:create_private_confdir)
        expect(karaf).not_to receive(:redirect_instances)

        expect { karaf.prepare(rebuild: true) }.to raise_error(ArgumentError, /contains it/)
        expect(File.read("#{live}/keep")).to eq "keep me"
      end
    end

    it "protects the registered root when userdata is elsewhere" do
      root = "#{clone_path}/registered root"
      register_root(root)
      write("#{root}/uuid", "keep me")

      expect { karaf.prepare(rebuild: true) }.to raise_error(ArgumentError, /contains it/)
      expect(File.read("#{root}/uuid")).to eq "keep me"
    end

    it "leaves the old clone intact when no root is registered" do
      write("#{userdata}/tmp/instances/instance.properties", "count = 0\n")
      write("#{clone_path}/uuid", "keep me")

      expect { karaf.prepare(rebuild: true) }.to raise_error(ArgumentError, /No root instance found/)
      expect(File.read("#{clone_path}/uuid")).to eq "keep me"
    end

    it "recreates private configuration directories after deleting the clone" do
      karaf.private_confdir = true
      karaf.send(:create_private_confdir)
      write("#{clone_path}/conf/items/old.items")

      karaf.prepare(rebuild: true)

      expect(File.exist?("#{clone_path}/conf/items/old.items")).to be false
      %w[items things scripts rules persistence sitemaps transform].each do |directory|
        expect(Dir.exist?("#{clone_path}/conf/#{directory}")).to be true
      end
    end

    it "rebuilds an already registered clone using a fresh instance registry" do
      karaf.prepare
      write("#{clone_path}/old/file")

      karaf.prepare(rebuild: true)

      expect(File.exist?("#{clone_path}/old")).to be false
      expect(File.read("#{clone_path}/uuid")).to eq "rebuilt"
      expect(File.read("#{clone_path}/instances/instance.properties")).to include("count = 2")
    end
  end

  describe "#cleanup_instance" do
    before do
      %i[cleanup_clone minimize_installed_features filter_addons].each { |step| allow(karaf).to receive(step) }
      allow(OpenHAB::RSpec::InstanceService).to receive(:isolate_clone)
    end

    it "isolates a clone from the instance it was cloned from" do
      karaf.instance_variable_set(:@root_userdata, "#{scratch}/root")

      karaf.send(:cleanup_instance)

      expect(OpenHAB::RSpec::InstanceService).to have_received(:isolate_clone).with("#{scratch}/root", clone_path)
    end

    it "isolates the clone before it cleans it up, which deletes files in it" do
      karaf.instance_variable_set(:@root_userdata, "#{scratch}/root")

      karaf.send(:cleanup_instance)

      expect(OpenHAB::RSpec::InstanceService).to have_received(:isolate_clone).ordered
      expect(karaf).to have_received(:cleanup_clone).ordered
    end

    it "has nothing to isolate when it is the real instance" do
      karaf.use_root_instance = true

      karaf.send(:cleanup_instance)

      expect(OpenHAB::RSpec::InstanceService).not_to have_received(:isolate_clone)
    end
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
end
