class VersionIndex
  attr_accessor :uid
  attr_accessor :name
  attr_reader :versions

  def initialize(uid)
    @uid = uid
    @versions = []
  end

  def add_version(version)
    if version.is_a? WonkoVersion
      remove_version version # remove any previous versions
      @versions << version
    end
  end

  def remove_version(version)
    @versions.select! do |ver|
      version.version != ver.version
    end
  end

  def self.get_full_version(version)
    if File.exist? version.local_filename
      Reader.read_version JSON.parse File.read(version.local_filename)
    else
      nil
    end
  end

  def local_filename
    VersionIndex.local_filename @uid
  end

  def self.local_filename(uid)
    'files/' + uid + '.json'
  end
end
