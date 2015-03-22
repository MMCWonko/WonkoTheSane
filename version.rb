class Download
  attr_accessor :internalUrl # not serialized, used for DownloadsFixer when the url isn't direct (requires user interaction)
  attr_accessor :url
  attr_accessor :size
  attr_accessor :sha256
  attr_accessor :rules # [Rule]

  def type
    'general.downloads'
  end

  def to_json
    obj = {
      url: url,
      size: @size,
      sha256: @sha256
    }
    obj[:rules] = @rules.map do |rule| rule.to_json end if @rules and not @rules.empty?
    return obj
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
    end

    dl.from_json json
    return dl
  end
end

class FileDownload < Download
  attr_accessor :destination

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
  attr_accessor :mavenBaseUrl

  def type
    'java.libraries'
  end
  def url
    @url ? @url : (@mavenBaseUrl + MavenIdentifier.new(@name).to_path)
  end

  def maven
    MavenIdentifier.new @name
  end

  def to_json
    obj = super
    obj[:name] = @name
    obj[:mavenBaseUrl] = @mavenBaseUrl if @mavenBaseUrl

    if not @url
      obj.delete :url
    end

    obj
  end

  def from_json(json)
    super
    @name = json[:name]
    @mavenBaseUrl = json[:mavenBaseUrl]

    # if the absolute url is equal to the expected maven url we clear the absolute url
    if @url == url
      @url = nil
    end
  end
end

class VersionLibraryNative < VersionLibrary
  def type
    'java.natives'
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
    @uid == other.uid and @version == other.version
  end
end

class Version
  attr_accessor :uid
  attr_accessor :version
  attr_reader :time # unix timestamp
  attr_accessor :type
  attr_accessor :is_complete

  attr_accessor :requires # list of Referenced

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

  attr_reader :client
  attr_reader :server
  attr_reader :common

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
    Version.local_filename @uid, @version
  end
  def self.local_filename(uid, version)
    'files/' + uid + '/' + version + '.json'
  end
end
