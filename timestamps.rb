require 'json'

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
      int = default.to_i
      if int.to_s == default
        return int
      else
        return DateTime.iso8601(default).to_time.to_i
      end
    elsif default.is_a? Fixnum
      return default
    else
      raise 'InvalidTimeFormat'
    end
  end

  @@me = Timestamps.new
  def self.get(uid, version, default = nil)
    @@me.get uid, version, default
  end
end