require_relative 'base_version_list'

class VanillaLegacyVersionList < BaseVersionList
  def initialize
    super('net.minecraft')
  end

  def get_versions
    result = Yajl::Parser.parse File.open('minecraft.json', 'r'), symbolize_names: true
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
    file.mainLib = VersionLibrary.new
    file.mainLib.name = 'net.minecraft:minecraft:' + file.version
    file.mainLib.absoluteUrl = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/' + file.version + '.jar'

    file.folders['minecraft/screenshots'] = ['general.screenshots']
    file.folders['minecraft/resourcepackks'] = ['mc.resourcepacks'] if file.time >= 1372430921
    file.folders['minecraft/texturepacks'] = ['mc.texturepacks'] if file.time < 1372430921
    file.folders['minecraft/saves'] = ['mc.saves.anvil'] if file.time >= 1330552800
    file.folders['minecraft/saves'] = ['mc.saves.region'] if file.time >= 1298325600 and file.time < 1330552800
    file.folders['minecraft/saves'] = ['mc.saves.infdev'] if file.time >= 1291327200 and file.time < 1298325600
    file.traits.remove 'texturepacks'
    file.traits.remove 'no-resourcepacks'

    BaseSanitizer.sanitize file, MojangProcessArgumentsSanitizer
  end
end