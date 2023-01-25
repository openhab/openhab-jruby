# frozen_string_literal: true

RSpec.describe "OpenHAB::Core::ValueCache" do
  describe "#key?" do
    it "returns false for missing keys" do
      expect(shared_cache).not_to have_key(:key)
      # do it twice, to prove we didn't accidentally insert nil
      expect(shared_cache).not_to have_key(:key)
    end

    it "returns true for set keys" do
      shared_cache[:key] = :value
      expect(shared_cache).to have_key(:key)
    end
  end

  describe "#[]" do
    it "works" do
      shared_cache[:key] = :value
      expect(shared_cache[:key]).to be :value
    end

    it "returns nil for keys that haven't been set" do
      expect(shared_cache[:key]).to be_nil
    end
  end

  describe "#compute_if_absent" do
    it "works" do
      expect(shared_cache.compute_if_absent(:key) { 0 }).to be 0
      expect(shared_cache.compute_if_absent(:key) { 1 }).to be 0
    end
  end

  describe "#delete" do
    it "works" do
      shared_cache[:key] = :value
      shared_cache.delete(:key)
      expect(shared_cache).not_to have_key(:key)
    end

    it "calls the block for missing keys" do
      expect(shared_cache.delete(:key) do |k|
        expect(k).to eql "key"
        :called
      end).to be :called
      expect(shared_cache).not_to have_key(:key)
    end
  end

  describe "#fetch" do
    it "raises KeyError on missing key" do
      expect { shared_cache.fetch(:key) }.to raise_error(KeyError)
    end

    it "returns a current value without calling the block" do
      shared_cache[:key] = :value
      expect(shared_cache.fetch(:key) { raise "not called" }).to be :value
    end

    it "calls the block on missing key, returning its value, but not setting it into the cache" do
      expect(shared_cache.fetch(:key) do |k|
        expect(k).to eql "key"
        :called
      end).to be :called
      expect(shared_cache).not_to have_key(:key)
    end

    it "returns the default value on missing key" do
      expect(shared_cache.fetch(:key, :default)).to be :default
      expect(shared_cache).not_to have_key(:key)
    end
  end

  describe "#assoc" do
    it "works" do
      shared_cache[:key] = :value
      expect(shared_cache.assoc(:key)).to eql %i[key value]
    end

    it "returns nil on missing key" do
      expect(shared_cache.assoc(:key)).to be_nil
      expect(shared_cache).not_to have_key(:key)
    end
  end

  describe "#dig" do
    it "works" do
      shared_cache[:key] = { a: 1 }
      expect(shared_cache.dig(:key, :a)).to be 1
      expect(shared_cache.dig(:key, :b)).to be_nil
      expect(shared_cache.dig(:key2, :a)).to be_nil
    end
  end

  describe "#fetch_values" do
    it "works" do
      shared_cache[:key1] = 1
      shared_cache[:key3] = 3

      expect(shared_cache.fetch_values(:key1, :key2, :key3)).to eql [1, 3]
      expect(shared_cache.fetch_values(:key1, :key2, :key3) { 4 }).to eql [1, 4, 3]
    end
  end

  describe "#merge!" do
    it "works" do
      shared_cache.merge!({ a: 1, b: 2 }, { a: 3 })
      expect(shared_cache[:a]).to be 3
      expect(shared_cache[:b]).to be 2
    end

    it "works with a block" do
      shared_cache.merge!({ a: 1, b: 2 }, { a: 3 }) do |k, old_value, new_value|
        expect(k).to eql "a"
        expect(old_value).to be 1
        expect(new_value).to be 3
        4
      end
      expect(shared_cache[:a]).to be 4
      expect(shared_cache[:b]).to be 2
    end
  end

  describe "#slice" do
    it "works" do
      shared_cache[:key1] = 1
      shared_cache[:key3] = 3

      expect(shared_cache.slice(:key1, :key2, :key3)).to eql({ "key1" => 1, "key3" => 3 })
    end
  end

  describe "#to_proc" do
    it "works" do
      proc = shared_cache.to_proc
      shared_cache[:key] = :value
      expect(proc.call(:key)).to be :value
      expect(proc.call(:key2)).to be_nil
    end
  end

  describe "#values_at" do
    it "works" do
      shared_cache[:key1] = 1
      shared_cache[:key3] = 3

      expect(shared_cache.values_at(:key1, :key2, :key3)).to eql [1, nil, 3]
    end
  end
end
