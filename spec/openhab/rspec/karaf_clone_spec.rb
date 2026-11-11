# frozen_string_literal: true

require "tmpdir"

RSpec.describe OpenHAB::RSpec::Karaf do
  let(:scratch) { File.realpath(Dir.mktmpdir("karaf clone spec")) }
  let(:clone_path) { "#{scratch}/openhab clone" }
  let(:karaf) { described_class.new(clone_path) }

  def write(file, contents = "contents of #{File.basename(file)}")
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, contents)
  end

  after { FileUtils.remove_entry(scratch) }

  describe "#find_jar_version" do
    it "finds the newest version even when the directory's path contains a dash" do
      FileUtils.mkdir_p("#{scratch}/open-hab/boot")
      FileUtils.touch(["#{scratch}/open-hab/boot/org.apache.karaf.main-4.4.11.jar",
                       "#{scratch}/open-hab/boot/org.apache.karaf.main-4.4.12.jar",
                       "#{scratch}/open-hab/boot/org.apache.karaf.other-5.0.0.jar"])

      expect(karaf.send(:find_jar_version, "#{scratch}/open-hab/boot", "org.apache.karaf.main")).to eq "4.4.12"
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
end
