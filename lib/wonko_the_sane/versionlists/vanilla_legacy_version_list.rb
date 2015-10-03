require_relative 'base_version_list'

class VanillaLegacyVersionList < BaseVersionList
  def initialize
    super 'net.minecraft'
  end

  def get_versions
    WonkoTheSane.data_json('minecraft.json')[:versions].map { |obj| [obj[:id], obj] }
  end

  def get_version(id)
    data = id[1]
    file = WonkoVersion.new
    file.uid = 'net.minecraft'
    file.version = data[:id]
    file.time = data[:releaseTime]
    file.type = data[:type]
    file.client.traits = data[:'+traits']
    file.client.extra[:processArguments] = data[:processArguments]
    file.client.mainClass = data[:mainClass] if data.has_key? :mainClass
    file.client.appletClass = data[:appletClass] if data.has_key? :appletClass
    main_lib = VersionLibrary.new
    main_lib.name = 'net.minecraft:minecraft:' + file.version
    main_lib.url = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/' + file.version + '.jar'
    file.client.downloads = [ main_lib ]

    file.client.folders['minecraft/screenshots'] = ['general.screenshots']
    file.client.folders['minecraft/resourcepackks'] = ['mc.resourcepacks'] if file.time >= 1372430921
    file.client.folders['minecraft/texturepacks'] = ['mc.texturepacks'] if file.time < 1372430921
    file.client.folders['minecraft/saves'] = ['mc.saves.anvil'] if file.time >= 1330552800
    file.client.folders['minecraft/saves'] = ['mc.saves.region'] if file.time >= 1298325600 and file.time < 1330552800
    file.client.folders['minecraft/saves'] = ['mc.saves.infdev'] if file.time >= 1291327200 and file.time < 1298325600
    file.client.traits.delete 'texturepacks' if file.client.traits
    file.client.traits.delete 'no-resourcepacks' if file.client.traits

    BaseSanitizer.sanitize file, MojangProcessArgumentsSanitizer
  end
end
