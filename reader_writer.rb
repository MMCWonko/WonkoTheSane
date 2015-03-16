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
      v.version = ver[:version]
      v.type = ver[:type]
      v.time = ver[:time]
      index.versions << v
    end

    return index
  end

  def read_download(data, key)
    if data[key.to_sym]
      return data[key.to_sym].map do |dl|
        Download.from_json key, dl
      end
    else
      return []
    end
  end

  def read_resource(data, res)
    return if not data or not data.is_a? Object
    res.traits = data[:'general.traits'] if data[:'general.traits']
    res.folders = data[:'general.folders'] if data[:'general.folders']
    res.downloads = []
    res.downloads << read_download(data, 'general.downloads')
    res.downloads << read_download(data, 'java.libraries')
    res.downloads << read_download(data, 'java.natives')
    res.downloads.flatten!

    res.mainClass = data[:'java.mainClass']
    res.appletClass = data[:'mc.appletClass']
    res.assets = data[:'mc.assets']
    res.minecraftArguments = data[:'mc.arguments']
    res.tweakers = data[:'mc.tweakers']
    res.serverLib = Download.from_json 'java.libraries', data[:'java.serverLib'] if data[:'java.serverLib']
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

    json[:data].each do |data|
      rules = data[:rules] ? data[:rules] : [ImplicitRule.new(:allow)]
      if Rule.allowed_on_side rules, :client
        read_resource data, file.client
      elsif Rule.allowed_on_side rules, :server
        read_resource data, file.server
      else
        read_resource data, file.common
      end
    end if json[:data]

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
      obj = { version: ver.version }
      obj[:type] = ver.type
      obj[:time] = ver.time
      json[:versions] << obj
    end

    return JSON.pretty_generate json
  end

  def write_resource(side, resource)
    data = {}

    if side == :client or side == :server
      data[:rules] = [
        ImplicitRule.new(:disallow).to_json,
        SidedRule.new(:allow, side).to_json
      ]
    end

    data[:'general.traits'] = resource.traits                      if resource.traits and not resource.traits.empty?
    data[:'general.launcher'] = :minecraft
    data[:'general.folders'] = resource.folders if resource.folders and not resource.folders.empty?
    resource.downloads.each do |dl|
      data[dl.type] = [] if not data[dl.type]
      data[dl.type] << dl.to_json
    end
    data[:'java.mainClass'] = resource.mainClass                   if resource.mainClass and resource.mainClass != ''
    data[:'java.serverLib'] = resource.serverLib.to_json     if resource.serverLib

    data[:'mc.tweakers'] = resource.tweakers                  if resource.tweakers and not resource.tweakers.empty?
    data[:'mc.appletClass'] = resource.appletClass               if resource.appletClass and resource.appletClass != ''
    data[:'mc.assets'] = resource.assets                         if resource.assets and resource.assets != ''
    data[:'mc.arguments'] = resource.minecraftArguments if resource.minecraftArguments and resource.minecraftArguments != ''

    return data
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

    json[:data] = []
    json[:data] << write_resource(:client, version.client) if version.is_complete
    json[:data] << write_resource(:server, version.server) if version.is_complete
    json[:data] << write_resource(:common, version.common) if version.is_complete

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
