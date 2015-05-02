require_relative 'base_version_list'

class ForgeVersionList < BaseVersionList
  def initialize(artifact = 'net.minecraftforge', url_id = 'forge')
    super(artifact)
    @input = ForgeInstallerProfileInput.new artifact
    @url_id = url_id
  end

  def get_versions
    result = get_json "http://files.minecraftforge.net/maven/net/minecraftforge/#{@url_id}/json"

    out = {}
    result[:number].values.each do |obj|
      out[obj[:build]] = obj.merge({
        artifact: result[:artifact],
        baseurl: result[:webpath]
      })
    end
    return out
  end

  def get_version(id)
    version = id[1][:mcversion] + '-' + id[1][:version]
    version += '-' + id[1][:branch] unless id[1][:branch].nil?

    result = []

    files = id[1][:files]
    installerFile = files.find do |file| file[1] == 'installer' end
    # installer versions of forge
    if not installerFile.nil? and id[1][:mcversion] != '1.5.2'
      path = "#{version}/#{id[1][:artifact]}-#{version}-#{installerFile[1]}.#{installerFile[0]}"
      url = id[1][:baseurl] + '/' + path
      HTTPCatcher.get url, ctxt: @artifact, key: 'forgeinstallers/' + path, check_stale: false
      result << @input.parse(ExtractionCache.get('cache/network/forgeinstallers/' + path, :zip, 'install_profile.json'), id[1][:version])
    else
      # non-installer versions of forge
    end
    return result.flatten
  end
end

class FMLVersionList < ForgeVersionList
  def initialize
    super('net.minecraftforge.fml', 'fml')
  end
end