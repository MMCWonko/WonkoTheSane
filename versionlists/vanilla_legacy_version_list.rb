require_relative 'base_version_list'

class VanillaLegacyVersionList < BaseVersionList
  def initialize
    super('net.minecraft')
  end

  def get_versions
    result = BaseVersionList.get_json 'https://cdn.rawgit.com/MultiMC/MultiMC5/develop/resources/versions/minecraft.json'
    return result[:versions].map do |obj| [obj[:id], obj] end
  end

  def get_version(id)
    data = id[1]
    file = Version.new
    file.uid = 'net.minecraft'
    file.version = data[:id]
    file.time = data[:releaseTime]
    file.type = data[:type]
    file.traits = data[:'+traits']
    file.extra[:processArguments] = data[:processArguments]
    file.mainClass = data[:mainClass] if data.has_key? :mainClass
    file.appletClass = data[:appletClass] if data.has_key? :appletClass

    BaseSanitizer.sanitize file, MojangProcessArgumentsSanitizer
  end
end