require 'hashie'

module Reader
  def read_version_index(data)
    json = Hashie::Mash.new JSON.parse(data, symbolize_names: true)

    index = VersionIndex.new json.uid
    index.name = json.name
    json.versions.each do |ver|
      v = Version.new
      v.is_complete = false
      v.uid = json.uid
      v.version = ver[:id]
      v.type = ver[:type]
      v.time = ver[:time]
      index.versions << v
    end

    return index
  end

  def read_library(json)
    lib = VersionLibrary.new
    lib.name = json.name
    lib.url = json.url
    lib.absoluteUrl = json.absoluteUrl
    lib.checksums = json.checksums
    lib.platforms = json.platforms
    lib.natives = json[:natives] if json[:natives]
    return lib
  end

  def read_version(data)
    json = Hashie::Mash.new JSON.parse(data)

    file = Version.new
    file.is_complete = true

    file.uid = json.uid
    file.version = json.version
    file.time = json.time
    file.type = json.type
    file.requires = json.requires.map do |req|
      Referenced.new(req[:uid], req[:version])
    end if json.requires

    json.data do |data|
      file.traits = data[:'general.traits'] if data[:'general.traits']
      file.folders = data[:'general.folders'] if data[:'general.folders']
      file.libraries = []
      data[:'java.libraries'].each do |lib|
        file.libraries << read_library(lib)
      end if data[:'java.libraries']

      file.mainClass = data[:'java.mainClass']
      file.appletClass = data[:'mc.appletClass']
      file.assets = data[:'mc.assets']
      file.minecraftArguments = data[:'mc.arguments']
      file.tweakers = data[:'mc.tweakers']
      file.mainLib = read_library data[:'java.mainLib'] if data[:'java.mainLib']
      file.serverLib = read_library data[:'java.serverLib'] if data[:'java.serverLib']
    end if json.data

    return file
  end

  def read_index(data)
    JSON.parse data, symbolize_names: true
  end
end

module Writer
  def write_version_index(index)
    json = {
        formatVersion: 0,
        uid: index.uid,
        name: index.name,
        versions: []
    }
    index.versions.each do |ver|
      obj = { id: ver.version }
      obj[:type] = ver.type
      obj[:time] = ver.time
      json[:versions] << obj
    end

    return JSON.pretty_generate json
  end

  def write_library(library)
    json = { name: library.name }
    json[:url] = library.url                 if library.url and library.url != ''
    json[:absoluteUrl] = library.absoluteUrl if library.absoluteUrl and library.absoluteUrl != ''
    json[:checksums] = library.checksums     if library.checksums and library.checksums != ''
    json[:platforms] = library.platforms     if library.platforms and library.platforms != VersionLibrary.possiblePlatforms
    json[:natives] = library.oldNatives      if library.oldNatives
    json[:rules] = library.oldRules          if library.oldRules
    return json
  end

  def write_version(version)
    # metadata
    json = {
        formatVersion: 0,
        uid: version.uid,
        version: version.version,
        time: version.time
    }
    json[:type] = version.type                             if version.type and version.type != ''
    json[:requires] = version.requires.map do |req|
      obj = { uid: req.uid }
      obj[:version] = req.version if req.version
      obj
    end if version.requires and not version.requires.empty?

    data = {}
    data[:'general.traits'] = version.traits                      if version.traits and not version.traits.empty?
    data[:'general.launcher'] = :minecraft
    data[:'general.folders'] = version.folders if version.folders and not version.folders.empty?

    data[:'java.mainClass'] = version.mainClass                   if version.mainClass and version.mainClass != ''
    data[:'java.mainLib'] = write_library version.mainLib         if version.mainLib
    data[:'java.serverLib'] = write_library version.serverLib     if version.serverLib
    data[:'java.libraries'] = version.libraries.reverse.map do |lib|
      write_library lib
    end if version.libraries

    data[:'mc.tweakers'] = version.tweakers                  if version.tweakers and not version.tweakers.empty?
    data[:'mc.appletClass'] = version.appletClass               if version.appletClass and version.appletClass != ''
    data[:'mc.assets'] = version.assets                         if version.assets and version.assets != ''
    data[:'mc.arguments'] = version.minecraftArguments if version.minecraftArguments and version.minecraftArguments != ''
    json[:data] = data

    return JSON.pretty_generate json
  end

  def write_index(index)
    return JSON.pretty_generate index
  end
end

class RW
  include Writer
  include Reader
end
$rw = RW.new
