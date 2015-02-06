require_relative 'base_version_list'
require 'zip'

class ForgeVersionList < BaseVersionList
  def initialize
    super('net.minecraftforge')
    @input = ForgeInstallerProfileInput.new('net.minecraftforge')
  end

  def get_versions
    result = BaseVersionList.get_json 'http://files.minecraftforge.net/maven/net/minecraftforge/forge/json'

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
    files = id[1][:files]
    file = files.find do |file| file[1] == 'installer' end
    version = id[1][:mcversion] + '-' + id[1][:version]
    version += '-' + id[1][:branch] unless id[1][:branch].nil?

    result = []

    unless file.nil?
      path = version + '/' + id[1][:artifact] + '-' + version + '-' + file[1] + '.' + file[0]
      url = id[1][:baseurl] + '/' + path
      HTTPCatcher.get url, 'forgeinstallers/' + path
      arch = Zip::File.open 'cache/network/forgeinstallers/' + path do |jarfile|
        result << @input.parse(jarfile.glob('install_profile.json').first.get_input_stream.read, version)
      end
    end
    return result
  end
end