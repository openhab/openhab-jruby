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
