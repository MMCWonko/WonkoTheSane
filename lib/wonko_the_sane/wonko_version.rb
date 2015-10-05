class Download
  attr_accessor :internal_url # not serialized, used for DownloadsFixer when the url isn't direct (requires user interaction)
  attr_accessor :url
  attr_accessor :size
  attr_accessor :sha256
  attr_accessor :rules # [Rule]

  def usable_url
    internal_url.nil? ? url : internal_url
  end

  def type
    'general.downloads'
  end

  def to_json
    obj = {
      url: url,
      size: @size,
      sha256: @sha256
    }
    obj[:rules] = @rules.map { |rule| rule.to_json } unless @rules.blank?
    obj
  end

  def from_json(json)
    @url = json[:url]
    @size = json[:size]
    @sha256 = json[:sha256]
    @rules = json[:rules].map do |obj| Rule.from_json obj end if json[:rules]
  end

  def self.from_json(type, json)
    dl = nil
    case type
    when 'java.libraries'
      dl = VersionLibrary.new
    when 'java.natives'
      dl = VersionLibraryNative.new
    when 'general.downloads'
      dl = FileDownload.new
    when 'mc.jarmods'
      dl = Jarmod.new
    end

    dl.from_json json
    return dl
  end
end

class FileDownload < Download
  attr_accessor :destination

  def initialize(url = nil, destination = nil)
    @url = url
    @destination = destination
  end

  def to_json
    obj = super
    obj[:destination] = @destination
    obj
  end

  def from_json(json)
    super
    @destination = json[:destination]
  end
end

class VersionLibrary < Download
  attr_accessor :name
  attr_accessor :maven_base_url

  def ==(other)
    self.class == other.class && name == other.name && url == other.url && sha256 == other.sha256 && rules == other.rules
  end

  def type
    'java.libraries'
  end
  def url
    if @url
      @url
    elsif @maven_base_url
      @maven_base_url + WonkoTheSane::Util::MavenIdentifier.new(@name).to_path
    else
      nil
    end
  end

  def explicit_url?
    !@url.nil?
  end

  def maven
    WonkoTheSane::Util::MavenIdentifier.new @name
  end

  def to_json
    obj = super
    obj[:name] = @name
    obj[:@maven_base_url] = @maven_base_url unless @maven_base_url.blank?

    unless @url
      obj.delete :url
    end

    obj
  end

  def from_json(json)
    super
    @name = json[:name]
    @maven_base_url = json[:@maven_base_url]

    # if the absolute url is equal to the expected maven url we clear the absolute url
    if @maven_base_url && @url == url
      @url = nil
    end
  end
end

class VersionLibraryNative < VersionLibrary
  def type
    'java.natives'
  end
end

class Jarmod < VersionLibrary
  def type
    'mc.jarmods'
  end
end

class Referenced
  attr_accessor :uid
  attr_accessor :version

  def initialize(uid, version = nil)
    @uid = uid
    @version = version
  end

  def ==(other)
    self.class == other.class && @uid == other.uid && @version == other.version
  end
end

class WonkoVersion
  attr_accessor :uid
  attr_accessor :name

  attr_accessor :version
  attr_reader :time # unix timestamp
  attr_accessor :type
  attr_accessor :is_complete

  attr_accessor :requires # [Referenced]

  class Resources
    attr_accessor :traits
    attr_accessor :launchMethod

    # resources
    attr_accessor :mainClass
    attr_accessor :appletClass
    attr_accessor :assets
    attr_accessor :minecraftArguments
    attr_accessor :tweakers
    attr_accessor :jarModTarget
    attr_accessor :folders # Path => [Type]
    attr_accessor :downloads # [Download]

    # for communication between sanitizers, parsers etc.
    attr_accessor :extra

    def initialize
      @extra = {}
      @folders = {}
      @downloads = []
    end
  end

  attr_accessor :client
  attr_accessor :server
  attr_accessor :common

  def initialize
    @requires = []
    @client = Resources.new
    @server = Resources.new
    @common = Resources.new
  end

  def time=(time)
    @time = Timestamps.get @uid, @version, time
  end

  def local_filename
    WonkoVersion.local_filename @uid, @version
  end
  def self.local_filename(uid, version)
    'files/' + uid + '/' + version + '.json'
  end
end
