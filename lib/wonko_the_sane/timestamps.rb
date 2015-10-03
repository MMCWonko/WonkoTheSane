class Timestamps
  def initialize
    @json = WonkoTheSane.data_json 'timestamps.json'
  end

  def get(uid, version, default = nil)
    if @json[uid.to_sym] && @json[uid.to_sym][version.to_sym]
      @json[uid.to_sym][version.to_sym]
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

  def self.get(uid, version, default = nil)
    @me ||= Timestamps.new
    @me.get uid, version, default
  end
end
