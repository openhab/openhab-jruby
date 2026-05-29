# frozen_string_literal: true

RSpec.describe OpenHAB::CoreExt::TimePredicates do
  around do |example|
    Timecop.freeze
    example.run
  ensure
    Timecop.return
  end

  describe "#within?" do
    let(:now) { ZonedDateTime.now }

    context "with the default anchor (now)" do
      it "returns true when a time is just within the epsilon in the past" do
        expect(4.minutes.ago.within?(5.minutes)).to be true
      end

      it "returns true when a time is just within the epsilon in the future" do
        expect(4.minutes.from_now.within?(5.minutes)).to be true
      end

      it "returns false when a time is outside the epsilon in the past" do
        expect(6.minutes.ago.within?(5.minutes)).to be false
      end

      it "returns false when a time is outside the epsilon in the future" do
        expect(6.minutes.from_now.within?(5.minutes)).to be false
      end
    end

    context "with an explicit anchor point using 'of:'" do
      let(:anchor) { now - 1.day }

      it "returns true when within epsilon of the custom anchor" do
        test_time = anchor - 4.minutes
        expect(test_time.within?(5.minutes, of: anchor)).to be true
      end

      it "returns false when outside epsilon of the custom anchor" do
        test_time = anchor + 6.minutes
        expect(test_time.within?(5.minutes, of: anchor)).to be false
      end
    end

    context "with different time types" do
      it "works correctly with Ruby Time objects" do
        ruby_now = Time.now
        expect((ruby_now - 2).within?(5, of: ruby_now)).to be true
        expect((ruby_now + 10).within?(5, of: ruby_now)).to be false
      end

      it "works through DateTimeType delegation" do
        state = DateTimeType.new(4.minutes.ago)

        expect(state.within?(5.minutes)).to be true
      end
    end
  end

  describe "#between?" do
    it "raises an ArgumentError when given only one argument that isn't a Range" do
      now = ZonedDateTime.now
      expect { now.between?(now) }.to raise_error(ArgumentError, /Expecting a range/)
    end
  end
end
