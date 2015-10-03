require_relative 'base_version_list'
require 'date'
require 'time'

class LiteLoaderVersionList < BaseVersionList
  def initialize
    super 'com.mumfrey.liteloader'
  end

  def get_versions
    result = get_json 'http://dl.liteloader.com/versions/versions.json'

    out = []
    result[:versions].each do |mcver|
      minecraft = mcver.first
      mcver[1][:artefacts].each do |artefact|
        if artefact.first == :'com.mumfrey:liteloader'
          latest = artefact[1].find { |i| i[0] == 'latest' }[1][:version]
          artefact[1].reject { |i| i.first == 'latest' }.each do |item|
            out << [
                item[1][:version],
                item[1].merge({
                  minecraft: minecraft.to_s,
                  type: latest == item[1][:version] ? 'latest' : nil
                })
            ]
          end
        end
      end
    end
    out
  end

  def get_version(id)
    liteloader_lib = VersionLibrary.new
    liteloader_lib.name = 'com.mumfrey:liteloader:' + id[1][:version]
    liteloader_lib.url = 'http://dl.liteloader.com/versions/com/mumfrey/liteloader/' + id[1][:minecraft] + '/' + id[1][:file]

    file = WonkoVersion.new
    file.uid = 'com.mumfrey.liteloader'
    file.version = id.first
    file.type =  'release' # id[1][:type]
    file.time = id[1][:timestamp]
    file.requires << Referenced.new('net.minecraft', id[1][:minecraft])
    file.client.tweakers = [ id[1][:tweakClass] ]
    file.client.mainClass = 'net.minecraft.launchwrapper.Launch'
    file.client.downloads = id[1][:libraries].map do |lib|
      libs = MojangInput.sanitize_mojang_library lib
      libs[0].maven_base_url = 'http://repo.maven.apache.org/maven2/' if lib[:name] == 'org.ow2.asm:asm-all:5.0.3'
      libs
    end.flatten 1
    file.client.folders['minecraft/mods'] = ['mc.liteloadermods']
    file.client.downloads << liteloader_lib
    BaseSanitizer.sanitize file
  end
end
