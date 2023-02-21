# frozen_string_literal: true

RSpec.describe java.util.List do
  subject(:list) { java.util.ArrayList.new([1, 2, 3]) }

  it "implements #assoc" do
    list.replace([{ foo: 0 }, [2, 4], [4, 5, 6], [4, 5]])
    expect(list.assoc(4)).to eql [4, 5, 6]
  end

  it "implements #at" do
    expect(list.at(0)).to be 1
    expect(list.at(-1)).to be 3
    expect(list.at(5)).to be_nil
    expect(list.at(-5)).to be_nil
  end

  it "implements #bsearch" do
    expect(list.bsearch { |x| x >= 3 }).to be 3
  end

  it "implements #bsearch_index" do
    expect(list.bsearch_index { |x| x >= 3 }).to be 2
  end

  it "implements #compact" do
    list.replace([1, nil, 2])
    expect(list.compact).to eql [1, 2]
  end

  it "implements #compact!" do
    list.replace([1, nil, 2])
    expect(list.compact!).to be list
    expect(list).to eq [1, 2]
  end

  it "implements #concat" do
    expect(list.concat([1, 2], [3, 4])).to be list # rubocop:disable Style/ConcatArrayLiterals
    expect(list).to eq [1, 2, 3, 1, 2, 3, 4]
  end

  it "implements #deconstruct" do
    expect(list.deconstruct).to be list
  end

  it "implements #delete" do
    expect(list.delete("a") { "b" }).to eq "b"
    expect(list.delete("b")).to be_nil

    list << 2
    expect(list.delete(2)).to be 2
    expect(list).to eq [1, 3]
  end

  it "implements #delete_at" do
    expect(list.delete_at(1)).to be 2
    expect(list).to eq [1, 3]
    expect(list.delete_at(5)).to be_nil
    expect(list.delete_at(-1)).to be 3
    expect(list).to eq [1]
    expect(list.delete_at(-5)).to be_nil
  end

  it "implements #delete_if" do
    expect(list.delete_if { |x| x == 2 }).to be list
    expect(list).to eq [1, 3]
  end

  it "implements #dig" do
    list.replace([:foo, [:bar, :baz, %i[bat bam]]])
    expect(list.dig(1)).to eql [:bar, :baz, %i[bat bam]] # rubocop:disable Style/SingleArgumentDig
    expect(list.dig(1, 2)).to eql %i[bat bam]
    expect(list.dig(1, 2, 0)).to be :bat
    expect(list.dig(1, 2, 3)).to be_nil
  end

  it "implements #each_index" do
    indices = []
    expect(list.each_index { |i| indices << i }).to be list
    expect(indices).to eql [0, 1, 2]
  end

  it "implements #fetch" do
    expect(list.fetch(1)).to be 2
    expect(list.fetch(-1)).to be 3
    expect { list.fetch(5) }.to raise_error(IndexError)
    expect { list.fetch(-5) }.to raise_error(IndexError)
    expect(list.fetch(5, 5)).to be 5
    expect(list.fetch(-5, 5)).to be 5
    expect(list.fetch(5) { |i| i }).to be 5
    expect(list.fetch(-5) { |i| i }).to be(-5)
  end

  describe "#fill" do
    subject(:list) { java.util.ArrayList.new(%w[a b c d]) }

    it "checks arguments" do
      expect { list.fill }.to raise_error(ArgumentError)
      expect { list.fill(1, 2, 3, 4) }.to raise_error(ArgumentError)
      expect { list.fill(1, 2, 3) { nil } }.to raise_error(ArgumentError)
    end

    it "returns `self`" do
      expect(list.fill(nil)).to be list
    end

    specify { expect(list.fill(:X)).to eq %i[X X X X] }
    specify { expect(list.fill(:X, 2)).to eq ["a", "b", :X, :X] }
    specify { expect(list.fill(:X, 4)).to eq %w[a b c d] }
    specify { expect(list.fill(:X, 5)).to eq %w[a b c d] }
    specify { expect(list.fill(:X, -2)).to eq ["a", "b", :X, :X] }
    specify { expect(list.fill(:X, -6)).to eq %i[X X X X] }
    specify { expect(list.fill(:X, -50)).to eq %i[X X X X] }
    specify { expect(list.fill(:X, 1, 1)).to eq ["a", :X, "c", "d"] }
    specify { expect(list.fill(:X, -2, 1)).to eq ["a", "b", :X, "d"] }
    specify { expect(list.fill(:X, 5, 0)).to eq ["a", "b", "c", "d", nil] }
    specify { expect(list.fill(:X, 5, 2)).to eq ["a", "b", "c", "d", nil, :X, :X] }
    specify { expect(list.fill(:X, 1, 0)).to eq %w[a b c d] }
    specify { expect(list.fill(:X, 1, -1)).to eq %w[a b c d] }
    specify { expect(list.fill(:X, 1..1)).to eq ["a", :X, "c", "d"] }
    specify { expect(list.fill(:X, -1..1)).to eq %w[a b c d] }
    specify { expect(list.fill(:X, 0..-2)).to eq [:X, :X, :X, "d"] }
    specify { expect(list.fill(:X, 1..-2)).to eq ["a", :X, :X, "d"] }
    specify { expect(list.fill(:X, -1..-1)).to eq ["a", "b", "c", :X] }
    specify { expect(list.fill(:X, -2..-2)).to eq ["a", "b", :X, "d"] }

    it "works with blocks" do
      expect(list.fill(&:to_s)).to eq %w[0 1 2 3]
    end
  end

  it "implements #flatten" do
    list.replace([1, [2, 3]])
    expect(list.flatten).to eql [1, 2, 3]
  end

  describe "#flatten!" do
    subject(:list) { java.util.ArrayList.new([0, [1, [2, 3], 4], 5]) }

    it "returns `self`" do
      expect(list.flatten!).to be list
    end

    specify { expect(list.flatten!(1)).to eq [0, 1, [2, 3], 4, 5] }
    specify { expect(list.flatten!(2)).to eq [0, 1, 2, 3, 4, 5] }
    specify { expect(list.flatten!(3)).to eq [0, 1, 2, 3, 4, 5] }
    specify { expect(list.flatten!).to eq [0, 1, 2, 3, 4, 5] }
    specify { expect(list.flatten!(-1)).to eq [0, 1, 2, 3, 4, 5] }
    specify { expect(list.flatten!(-2)).to eq [0, 1, 2, 3, 4, 5] }

    it "returns nil if no change" do
      list.replace([1, 2, 3])
      expect(list.flatten!(1)).to be_nil
      expect(list.flatten!).to be_nil
      expect(list.flatten!(-1)).to be_nil
    end
  end

  describe "#insert" do
    subject(:list) { java.util.ArrayList.new([:foo, "bar", 2]) }

    it "returns `self`" do
      expect(list.insert(0)).to be list
    end

    specify { expect(list.insert(1, :bat, :bam)).to eq [:foo, :bat, :bam, "bar", 2] }
    specify { expect(list.insert(5, :bat, :bam)).to eq [:foo, "bar", 2, nil, nil, :bat, :bam] }
    specify { expect(list.insert(1)).to eq [:foo, "bar", 2] }
    specify { expect(list.insert(50)).to eq [:foo, "bar", 2] }
    specify { expect(list.insert(-50)).to eq [:foo, "bar", 2] }
    specify { expect(list.insert(-2, :bat, :bam)).to eq [:foo, "bar", :bat, :bam, 2] }
  end

  it "implements #intersect?" do
    expect(list.intersect?([3, 4, 5])).to be true
    expect(list.intersect?([4, 5, 6])).to be false
  end

  it "implements #keep_if?" do
    expect(list.keep_if? { |v| v >= 2 }).to be list
    expect(list).to eq [2, 3]
  end

  it "implements #map!" do
    expect(list.map!(&:to_s)).to be list
    expect(list).to eq %w[1 2 3]
  end

  it "implements #pop" do
    expect(list.pop).to be 3
    expect(list).to eq [1, 2]

    list.replace([1, 2, 3])
    expect(list.pop(2)).to eql [2, 3]
    expect(list).to eq [1]

    list.replace([1, 2, 3])
    expect(list.pop(50)).to eql [1, 2, 3]
    expect(list).to be_empty
  end

  it "implements #push" do
    expect(list.push(4)).to be list
    expect(list).to eq [1, 2, 3, 4]
  end

  it "implements #rassoc" do
    list.replace([{ foo: 0 }, [2, 4], [4, 5, 6], [4, 5]])
    expect(list.rassoc(4)).to eql [2, 4]
  end

  it "implements #reject!" do
    expect(list.reject! { |x| x < 3 }).to be list
    expect(list).to eq [3]
    expect(list.reject! { |x| x < 3 }).to be_nil
  end

  it "implements #replace" do
    expect(list.replace([4, 5, 6])).to be list
    expect(list).to eq [4, 5, 6]
  end

  it "implements #reverse!" do
    expect(list.reverse!).to be list
    expect(list).to eq [3, 2, 1]
  end

  it "implements #rotate!" do
    expect(list.rotate!).to be list
    expect(list).to eq [2, 3, 1]

    list.replace([1, 2, 3, 4, 5])
    expect(list.rotate!(2)).to eq [3, 4, 5, 1, 2]
    expect(list.rotate!(-3)).to eq [5, 1, 2, 3, 4]
  end

  it "implements #select!" do
    expect(list.select! { |v| v < 3 }).to be list
    expect(list).to eq [1, 2]
  end

  it "implements #shift" do
    expect(list.shift).to be 1
    expect(list).to eq [2, 3]

    list.replace([1, 2, 3, 4, 5])
    expect(list.shift(3)).to eql [1, 2, 3]
    expect(list).to eq [4, 5]

    expect(list.shift(50)).to eql [4, 5]
    expect(list).to be_empty
  end

  it "implements #shuffle!" do
    raw_array = (1..100).to_a
    list.replace(raw_array)
    list.shuffle!
    expect(list.to_a).to match_array(raw_array)
    expect(list).not_to eq raw_array
  end

  it "implements #slice" do
    expect(list.slice(1..2)).to eq [2, 3]
  end

  describe "#slice!" do
    specify do
      expect(list.slice!(1)).to be 2
      expect(list).to eq [1, 3]
    end

    specify do
      expect(list.slice!(-1)).to be 3
      expect(list).to eq [1, 2]
    end

    specify do
      expect(list.slice!(0, 2)).to eql [1, 2]
      expect(list).to eq [3]
    end

    specify do
      expect(list.slice!(1, 50)).to eql [2, 3]
      expect(list).to eq [1]
    end

    specify do
      expect(list.slice!(0..-2)).to eql [1, 2]
      expect(list).to eq [3]
    end

    specify do
      expect(list.slice!(-2..2)).to eql [2, 3]
      expect(list).to eq [1]
    end
  end

  it "implements #sort_by!" do
    expect(list.sort_by!(&:-@)).to be list
    expect(list).to eq [3, 2, 1]
  end

  it "implements #uniq!" do
    list.replace([0, 0, 1, 1, 2, 2])
    expect(list.uniq!).to be list
    expect(list).to eq [0, 1, 2]

    list.replace(%w[a aa aaa b bb bbb])
    list.uniq!(&:size)
    expect(list).to eq %w[a aa aaa]

    expect(list.uniq!).to be_nil
  end

  it "implements #unshift" do
    expect(list.unshift(0)).to be list
    expect(list).to eq [0, 1, 2, 3]

    list.unshift(-2, -1)
    expect(list).to eq [-2, -1, 0, 1, 2, 3]

    list.unshift
    expect(list).to eq [-2, -1, 0, 1, 2, 3]
  end

  describe "#values_at" do
    subject(:list) { java.util.ArrayList.new([:foo, "bar", 2]) }

    specify { expect(list.values_at(0, 2)).to eql [:foo, 2] }
    specify { expect(list.values_at(0..1)).to eql [:foo, "bar"] }
    specify { expect(list.values_at(2, 0, 1, 0, 2)).to eql [2, :foo, "bar", :foo, 2] }
    specify { expect(list.values_at(1, 0..2)).to eql ["bar", :foo, "bar", 2] }
    specify { expect(list.values_at(0, 3, 1, 3)).to eql [:foo, nil, "bar", nil] }
    specify { expect(list.values_at(-1, -3)).to eql [2, :foo] }
    specify { expect(list.values_at(0, -5, 1, -6, 2)).to eql [:foo, nil, "bar", nil, 2] }
    specify { expect(list.values_at(0, -2, 1, -1)).to eql [:foo, "bar", "bar", 2] }
  end
end
