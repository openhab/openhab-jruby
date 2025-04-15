# frozen_string_literal: true

# @!visibility private
module Java::JavaUtil::List # rubocop:disable Style/ClassAndModuleChildren
  extend Forwardable

  def_delegators :to_a,
                 :&,
                 :*,
                 :|,
                 :bsearch_index,
                 :difference,
                 :flatten,
                 :intersection,
                 :pack,
                 :product,
                 :repeated_combination,
                 :repeated_permutation,
                 :reverse,
                 :rotate,
                 :sample,
                 :shelljoin,
                 :shuffle,
                 :transpose,
                 :union

  def assoc(obj)
    find { |v| (v.is_a?(Array) || v.is_a?(self.class)) && v[0] == obj }
  end

  def at(index)
    self[index]
  end

  def bsearch(&block)
    raise NotImplementedError unless block

    r = bsearch_index(&block)
    self[r] if r
  end

  def combination(n, &block) # rubocop:disable Naming/MethodParameterName
    r = to_a.combination(n, &block)
    block ? self : r
  end

  def compact
    reject(&:nil?)
  end

  def compact!
    reject!(&:nil?)
  end

  def concat(*other_arrays)
    other_arrays.each { |array| add_all(array) }
    self
  end

  def deconstruct
    self
  end

  def delete(obj)
    last = nil
    found = false
    loop do
      i = index(obj)
      break if i.nil?

      found = true
      last = remove(i)
    end

    return yield(obj) if !found && block_given?

    last
  end

  def delete_at(index)
    index = length + index if index.negative?
    return if index.negative? || index >= length

    remove(index)
  end

  def delete_if
    raise NotImplementedError unless block_given?

    itr = list_iterator
    while itr.has_next? # rubocop:disable Style/WhileUntilModifier
      itr.remove if yield(itr.next)
    end
    self
  end

  def dig(index, *identifiers)
    return self[index] if identifiers.empty?

    self[index]&.dig(*identifiers)
  end

  def each_index(&block)
    r = (0...length)
    return r.each unless block

    r.each(&block)
    self
  end

  def fetch(index, *default_value)
    if default_value.length > 1
      raise ArgumentError,
            "wrong number of arguments calling `fetch` (given #{default_value.length - 1}, expected 1..2)"
    end

    original_index = index
    index = length + index if index.negative?
    return self[index] if index >= 0 && index < length

    return default_value.first unless default_value.empty?
    return yield(original_index) if block_given?

    raise IndexError, "index #{index} out of list"
  end

  def fill(*args)
    if block_given?
      unless (0..2).cover?(args.length)
        raise ArgumentError,
              "wrong number of arguments calling `fill` (given #{args.length}, expected 1..3)"
      end
    else
      unless (1..3).cover?(args.length)
        raise ArgumentError,
              "wrong number of arguments calling `fill` (given #{args.length}, expected 1..2)"
      end
    end

    obj = args.shift unless block_given?

    if args.length == 1 && args.first.is_a?(Range)
      range = args.first

      range = Range.new(length + range.begin, range.end, range.exclude_end?) if range.begin.negative?
      range = Range.new(range.begin, length + range.end, range.exclude_end?) if range.end&.negative?
      return self if range.begin.negative? || (range.end && range.end < range.begin)
    else
      first, count = *args
      return self if count&.negative?

      first ||= 0

      first = length + first if first.negative?
      range = count ? first...(first + count) : first..
    end

    add(nil) while length < range.begin && count

    start = range.begin
    start = 0 if start.negative?
    start = length if start > length
    itr = list_iterator(start)

    while range.cover?(itr.next_index)
      break if range.end.nil? && !itr.has_next?

      obj = yield(itr.next_index) if block_given?
      if itr.has_next?
        itr.next
        itr.set(obj)
      else
        itr.add(obj)
      end
    end

    self
  end

  def flatten!(*args)
    if args.length > 1
      raise ArgumentError,
            "wrong number of arguments calling `flatten` (given #{args.length}, expect 0..1)"
    end

    itr = list_iterator

    args = [args.first - 1] unless args.empty?
    done = args.first == 0 # rubocop:disable Style/NumericPredicate

    changed = false
    while itr.has_next?
      element = itr.next
      next unless element.respond_to?(:to_ary)

      changed = true
      itr.remove
      arr = element.to_ary
      arr = arr.flatten(*args) unless done
      arr.each do |e|
        itr.add(e)
      end
    end
    changed ? self : nil
  end

  def insert(index, *objects)
    return self if objects.empty?

    raise IndexError, "index #{index} too small for list, minimum: #{-length}" if index < -length

    index = length + index + 1 if index.negative?

    add(nil) while length < index
    add_all(index, objects)
    self
  end

  def intersect?(other_ary)
    !(self & other_ary).empty? # rubocop:disable Style/ArrayIntersect
  end

  def keep_if?
    raise NotImplementedError unless block_given?

    itr = list_iterator
    while itr.has_next? # rubocop:disable Style/WhileUntilModifier
      itr.remove unless yield(itr.next)
    end
    self
  end

  def map!(&block)
    raise NotImplementedError unless block

    replace_all(&block)
    self
  end

  def permutation(n, &block) # rubocop:disable Naming/MethodParameterName
    r = to_a.permutation(n, &block)
    block ? self : r
  end

  def pop(*args)
    if args.length > 1
      raise ArgumentError,
            "wrong number of arguments calling `pop` (given #{args.length}, expected 0..1)"
    end

    if args.empty?
      return if empty?

      return remove(length - 1)
    end

    count = args.first
    start = [length - count, 0].max
    result = self[start..-1].to_a # rubocop:disable Style/SlicingWithRange
    itr = list_iterator(start)
    while itr.has_next?
      itr.next
      itr.remove
    end
    result
  end

  def push(*objects)
    add_all(objects)
    self
  end
  alias_method :append, :push

  def rassoc(obj)
    find { |v| (v.is_a?(Array) || v.is_a?(self.class)) && v[1] == obj }
  end

  def reject!
    raise NotImplementedError unless block_given?

    itr = list_iterator
    changed = false
    while itr.has_next
      if yield(itr.next)
        changed = true
        itr.remove
      end
    end
    self if changed
  end

  def repeated_combination(n, &block) # rubocop:disable Naming/MethodParameterName
    r = to_a.repeated_combination(n, &block)
    block ? self : r
  end

  def repeated_permutation(n, &block) # rubocop:disable Naming/MethodParameterName
    r = to_a.repeated_permutation(n, &block)
    block ? self : r
  end

  def replace(other_array)
    clear
    add_all(other_array)
    self
  end

  def reverse!
    replace(reverse)
    self
  end

  def rotate!(count = 1)
    count %= length
    push(*shift(count))
    self
  end

  def select!
    raise NotImplementedError unless block_given?

    itr = list_iterator
    changed = false
    while itr.has_next?
      unless yield(itr.next)
        changed = true
        itr.remove
      end
    end
    self if changed
  end

  def shift(*args)
    if args.length > 1
      raise ArgumentError,
            "wrong number of arguments calling `shift` (given #{args.length}, expected 0..1)"
    end

    if args.empty?
      return if empty?

      return remove(0)
    end

    count = args.first
    result = self[0...count].to_a
    itr = list_iterator
    count.times do
      break unless itr.has_next?

      itr.next
      itr.remove
    end
    result
  end

  def shuffle!(*args)
    replace(shuffle(*args))
  end

  def slice(*args)
    self[*args]
  end

  def slice!(*args)
    unless (1..2).cover?(args.length)
      raise ArgumentError,
            "wrong number of arguments calling `slice!` (given #{args.length}, expected 1..2)"
    end

    return delete_at(args.first) if args.length == 1 && !args.first.is_a?(Range)

    start = args.first
    start = start.begin if start.is_a?(Range)
    start = length + start if start.negative?
    return nil if start.negative? || start >= length

    result = slice(*args).to_a

    itr = list_iterator(start)
    result.length.times do
      itr.next
      itr.remove
    end
    result
  end

  def sort_by!
    raise NotImplementedError unless block_given?

    sort { |a, b| (yield a) <=> (yield b) }
    self
  end

  def uniq!
    seen = Set.new

    itr = list_iterator
    changed = false
    while itr.has_next?
      n = itr.next
      n = yield(n) if block_given?
      if seen.include?(n)
        changed = true
        itr.remove
      end
      seen << n
    end
    self if changed
  end

  def unshift(*objects)
    add_all(0, objects)
    self
  end
  alias_method :prepend, :unshift

  def values_at(*indexes)
    result = []
    indexes.each do |index|
      if index.is_a?(Range)
        partial_result = self[index]
        result.concat(partial_result)
        result.fill(nil, result.length, index.count - partial_result.length)
      else
        index = length + index if index.negative?
        result << if index.negative? || index >= length
                    nil
                  else
                    self[index]
                  end
      end
    end
    result
  end
end
