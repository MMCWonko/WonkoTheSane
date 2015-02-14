require 'json'

# TODO this is a resource, and should be moved elsewhere
class VersionLibrary
  attr_accessor :name
  attr_accessor :url
  attr_accessor :absoluteUrl
  attr_accessor :checksums # map of algorithm => hash
  attr_accessor :platforms # list of platforms ({lin,win,osx}{32,64}), or empty for all
  attr_accessor :natives # map of platform => id

  @@possiblePlatforms = [ 'win32', 'win64', 'lin32', 'lin64', 'osx64' ]
  def self.possiblePlatforms
    @@possiblePlatforms
  end
end

class Version
  attr_accessor :uid
  attr_accessor :version
  attr_reader :time # unix timestamp
  attr_accessor :type
  attr_accessor :is_complete

  # TODO these are resources, and should be moved elsewhere
  attr_accessor :mainClass
  attr_accessor :appletClass
  attr_accessor :assets
  attr_accessor :minecraftArguments
  attr_accessor :tweakers
  attr_accessor :requires
  attr_accessor :libraries # list of VersionLibrary
  attr_accessor :traits

  attr_accessor :extra

  def initialize
    @extra = {}
    @requires = []
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