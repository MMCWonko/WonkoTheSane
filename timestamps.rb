require 'yajl/json_gem'

class Timestamps
  def initialize
    @json = JSON.parse File.read('timestamps.json')
  end

  def get(uid, version, default = nil)
    if @json[uid] and @json[uid][version]
      return @json[uid][version]
    elsif default.nil?
      raise 'No timestamp available for ' + uid + ': ' + version
    elsif default.is_a? String
      if default.to_i.to_s == default
        return default.to_i
      else
        return DateTime.parse(default).to_time.to_i
      end
    elsif default.is_a? Fixnum
      return default
    elsif default.is_a? Float
      return default.to_i
    else
      raise 'InvalidTimeFormat'
    end
  end

  @@me = Timestamps.new
  def self.get(uid, version, default = nil)
    @@me.get uid, version, default
  end
end