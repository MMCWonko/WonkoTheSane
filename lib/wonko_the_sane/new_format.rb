module Reader
  def read_version_index(data)
    data = data.with_indifferent_access
    index = VersionIndex.new data[:uid]
    index.name = data[:name]
    data[:versions].each do |ver|
      v = WonkoVersion.new
      v.is_complete = false
      v.uid = data[:uid]
      v.version = ver[:version]
      v.type = ver[:type]
      v.time = ver[:time]
      index.versions << v
    end

    index
  end

  def read_download(data, key)
    if data[key.to_sym]
      data[key.to_sym].map { |dl| Download.from_json key, dl }
    else
      []
    end
  end

  def read_resource(data)
    return if !data || !data.is_a?(Object)
    res = WonkoVersion::Resources.new
    res.traits = data[:'general.traits'] if data[:'general.traits']
    res.folders = data[:'general.folders'] if data[:'general.folders']
    res.launchMethod = data[:'general.launcher'] if data[:'general.launcher']
    res.downloads = []
    res.downloads << read_download(data, 'general.downloads')
    res.downloads << read_download(data, 'java.libraries')
    res.downloads << read_download(data, 'java.natives')
    res.downloads << read_download(data, 'mc.jarmods')
    res.downloads.flatten!

    res.mainClass = data[:'java.mainClass']
    res.appletClass = data[:'mc.appletClass']
    res.assets = data[:'mc.assets']
    res.minecraftArguments = data[:'mc.arguments']
    res.tweakers = data[:'mc.tweakers']
    res.jarModTarget = data[:'mc.jarModTarget'] if data[:'mc.jarModTarget']
    res
  end

  def read_version(data)
    data = data.with_indifferent_access

    file = WonkoVersion.new
    file.is_complete = true

    file.uid = data[:uid]
    file.version = data[:version]
    file.time = data[:time]
    file.type = data[:type]
    file.requires = data[:requires].map { |req| Referenced.new(req[:uid], req[:version]) } if data[:requires]

    data[:data].each do |group|
      rules = group[:rules] ? group[:rules] : [ImplicitRule.new(:allow)]
      if Rule.allowed_on_side(rules, :client) && Rule.allowed_on_side(rules, :server)
        file.common = read_resource group
      elsif Rule.allowed_on_side rules, :server
        file.server = read_resource group
      else
        file.client = read_resource group
      end
    end if data[:data]

    file
  end

  def read_index(data)
    data.with_indifferent_access
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

    json
  end

  def write_resource(side, resource, out)
    data = {}

    data[:'general.traits'] = resource.traits                      if resource.traits and not resource.traits.empty?
    data[:'general.launcher'] = resource.launchMethod              if resource.launchMethod
    data[:'general.folders'] = resource.folders                    if resource.folders and not resource.folders.empty?
    resource.downloads.each do |dl|
      data[dl.type] = [] unless data[dl.type]
      data[dl.type] << dl.to_json
    end
    data[:'java.mainClass'] = resource.mainClass                   if resource.mainClass and resource.mainClass != ''
    data[:'mc.jarModTarget'] = resource.jarModTarget               if resource.jarModTarget

    data[:'mc.tweakers'] = resource.tweakers                       if resource.tweakers and not resource.tweakers.empty?
    data[:'mc.appletClass'] = resource.appletClass                 if resource.appletClass and resource.appletClass != ''
    data[:'mc.assets'] = resource.assets                           if resource.assets and resource.assets != ''
    data[:'mc.arguments'] = resource.minecraftArguments            if resource.minecraftArguments and resource.minecraftArguments != ''

    unless data.empty?
      if side == :client || side == :server
        data[:rules] = [
          ImplicitRule.new(:disallow).to_json,
          SidedRule.new(:allow, side).to_json
        ]
      end
      out << data
    end
  end

  def write_version(version)
    # metadata
    json = {
        formatVersion: 0,
        uid: version.uid,
        version: version.version,
        time: version.time.to_s,
        type: version.type,
        data: [],
        requires: []
    }
    json[:requires] = version.requires.map do |req|
      obj = { uid: req.uid }
      obj[:version] = req.version if req.version
      obj
    end if version.requires and not version.requires.empty?

    write_resource(:client, version.client, json[:data]) if version.is_complete
    write_resource(:server, version.server, json[:data]) if version.is_complete
    write_resource(:common, version.common, json[:data]) if version.is_complete

    json
  end

  def write_index(index)
    index
  end
end

class RW
  include Writer
  include Reader
end
$rw = RW.new
