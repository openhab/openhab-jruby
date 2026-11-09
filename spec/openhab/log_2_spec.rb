# frozen_string_literal: true

RSpec.describe OpenHAB::Log do
  describe "#name" do
    # have to use a separate file to ensure that the logger isn't getting cached
    # between files, but having the same name
    it "uses the file name at the top level" do
      expect(logger.name).to eql "org.openhab.automation.jrubyscripting.log_2_spec"
    end
  end
end
