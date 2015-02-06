require 'json'

class VersionLibrary
  attr_accessor :name
  attr_accessor :url
  attr_accessor :absoluteUrl
  attr_accessor :checksums # map of algorithm => hash
  attr_accessor :platforms # list of platforms ({lin,win,osx}{32,64}), or empty for all

  @@possiblePlatforms = [ 'win32', 'win64', 'lin32', 'lin64', 'osx64' ]
  def self.possiblePlatforms
    @@possiblePlatforms
  end

  def self.from_json(object, clazz = VersionLibrary)
    lib = clazz.new
    lib.name = object[:name]
    lib.url = object[:url]
    lib.absoluteUrl = object[:absoluteUrl]
    lib.checksums = object[:checksums]
    lib.platforms = object[:platforms]
    return lib
  end

  def to_hash
    object = { name: @name }
    object[:url] = @url if @url and @url != ''
    object[:absoluteUrl] = @absoluteUrl if @absoluteUrl and @absoluteUrl != ''
    object[:checksums] = @checksums if @checksums and @checksums != ''
    object[:platforms] = @platforms if @platforms and @platforms != @@possiblePlatforms
    return object
  end
end

class VersionNative < VersionLibrary
  attr_accessor :natives # map of platform => id

  def self.from_json(object)
    lib = VersionLibrary.from_json object, VersionNative
    lib.natives = object[:natives]
    return lib
  end

  def to_hash
    object = super.to_hash
    object[:natives] = @natives
    return object
  end
end

class VersionFile
  attr_accessor :id
  attr_accessor :version
  attr_accessor :versionName
  attr_accessor :time # ISO formatted date of release
  attr_accessor :type

  attr_accessor :mainClass
  attr_accessor :assets
  attr_accessor :minecraftArguments
  attr_accessor :tweakers
  attr_accessor :requires
  attr_accessor :libraries # list of VersionLibrary
  attr_accessor :natives # list of VersionNative

  def self.from_json(data)
    parsed = JSON.parse data, symbolize_names: true

    file = VersionFile.new

    file.id = parsed[:id]
    file.version = parsed[:version]
    file.versionName = parsed.has_key? :versionName ? parsed[:versionName] : nil
    file.time = parsed[:time]
    file.type = parsed[:type]

    file.mainClass = parsed[:mainClass]
    file.assets = parsed[:assets]
    file.minecraftArguments = parsed[:minecraftArguments]
    file.tweakers = parsed[:tweakers]
    file.requires = parsed[:requires]

    file.libraries = []
    parsed[:libraries].each do |lib|
      file.libraries << VersionLibrary.from_json(lib)
    end if parsed[:libraries]

    file.natives = []
    parsed[:natives].each do |native|
      file.natives << VersionNative.from_json(native)
    end if parsed[:natives]

    return file
  end

  def to_json
    object = {
        id: @id,
        version: @version,
        time: @time,
        type: @type,
        tweakers: @tweakers,
        requires: @requires,
        libraries: @libraries.map { |lib| lib.to_hash },
        natives: @natives.map { |native| native.to_hash }
    }

    object[:versionName] = @versionName               if @versionName and @versionName != ''
    object[:mainClass] = @mainClass                   if @mainClass and @mainClass != ''
    object[:assets] = @assets                         if @assets and @assets != ''
    object[:minecraftArguments] = @minecraftArguments if @minecraftArguments and @minecraftArguments != ''

    return JSON.pretty_generate object
  end
end