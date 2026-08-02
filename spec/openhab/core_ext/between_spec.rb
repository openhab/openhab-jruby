# frozen_string_literal: true

RSpec.describe OpenHAB::CoreExt::Between do
  around do |example|
    Timecop.freeze
    example.run
  ensure
    Timecop.return
  end

  describe "#between?" do
    it "raises an ArgumentError when given only one argument that isn't a Range" do
      now = ZonedDateTime.now
      expect { now.between?(now) }.to raise_error(ArgumentError, /Expecting a range/)
    end
  end
end
