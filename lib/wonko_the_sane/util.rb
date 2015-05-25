module Util
  def self.deep_map_keys(val, &block)
    Util.deep_map_hash val do |k, v|
      [yield(k), v]
    end
  end

  def self.deep_map(val, &block)
    if val.is_a? Array
      val.map { |item| deep_map_hash item, &block }
    elsif val.is_a? Hash
      Hash[val.map { |k, v| yield k, deep_map_hash(v, &block) }]
    else
      yield nil, val
    end
  end
end
