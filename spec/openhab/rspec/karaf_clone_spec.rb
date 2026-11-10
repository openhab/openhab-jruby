# frozen_string_literal: true

require "tmpdir"

RSpec.describe OpenHAB::RSpec::Karaf do
  let(:scratch) { File.realpath(Dir.mktmpdir("karaf clone spec")) }
  let(:karaf) { described_class.new("#{scratch}/clone") }

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
end
