# frozen_string_literal: true

# @!visibility private
module Java::JavaUtil::Map # rubocop:disable Style/ClassAndModuleChildren
  def compact
    reject { |_k, v| v.nil? }
  end

  def compact!
    reject! { |_k, v| v.nil? }
    self
  end

  def deconstruct_keys
    self
  end

  def except(*keys)
    reject { |k, _v| keys.include?(k) } # rubocop:disable Style/HashExcept
  end

  def slice(*keys)
    select { |k, _v| keys.include?(k) } # rubocop:disable Style/HashSlice
  end

  def transform_keys(hash2 = nil)
    raise NotImplementedError unless hash2 || block_given?

    map do |k, v| # rubocop:disable Style/MapToHash
      if hash2&.key?(k)
        [hash2[k], v]
      elsif block_given?
        [(yield k), v]
      else
        [k, v]
      end
    end.to_h
  end

  def transform_keys!(hash2 = nil)
    raise NotImplementedError unless hash2 || block_given?

    keys.each do |k|
      if hash2&.key?(k)
        self[hash2[k]] = delete(k)
      elsif block_given?
        new_k = yield k
        self[new_k] = delete(k) unless new_k == k
      end
    end
    self
  end

  def transform_values
    map do |k, v| # rubocop:disable Style/MapToHash, Style/HashTransformValues
      [k, (yield v)]
    end.to_h
  end

  def transform_values!
    replace_all do |_k, v|
      yield v
    end
    self
  end
end
