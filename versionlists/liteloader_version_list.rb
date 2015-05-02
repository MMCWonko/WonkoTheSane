require_relative 'base_version_list'
require 'date'
require 'time'

class LiteLoaderVersionList < BaseVersionList
  def initialize
    super('com.mumfrey.liteloader')
  end

  def get_versions
    result = get_json 'http://dl.liteloader.com/versions/versions.json'

    out = []
    result[:versions].each do |mcver|
      minecraft = mcver.first
      mcver[1][:artefacts].each do |artefact|
        if artefact.first == :'com.mumfrey:liteloader'
          latest = nil
          artefact[1].each do |item|
            if item.first == 'latest'
              latest = item[1][:version]
              break
            end
          end
          artefact[1].each do |item|
            if item.first != 'latest'
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
    end
    return out
  end

  def get_version(id)
    liteloaderLib = VersionLibrary.new
    liteloaderLib.name = 'com.mumfrey:liteloader:' + id[1][:version]
    liteloaderLib.url = 'http://dl.liteloader.com/versions/com/mumfrey/liteloader/' + id[1][:minecraft] + '/' + id[1][:file]

    file = Version.new
    file.uid = 'com.mumfrey.liteloader'
    file.version = id.first
    file.type =  'release' # id[1][:type]
    file.time = id[1][:timestamp]
    file.requires << Referenced.new('net.minecraft', id[1][:minecraft])
    file.client.tweakers = [ id[1][:tweakClass] ]
    file.client.mainClass = 'net.minecraft.launchwrapper.Launch'
    file.client.downloads = id[1][:libraries].map do |lib|
      libs = MojangInput.sanetize_mojang_library lib
      if lib[:name] == 'org.ow2.asm:asm-all:5.0.3'
        libs[0].mavenBaseUrl = 'http://repo.maven.apache.org/maven2/'
      end
      libs
    end.flatten 1
    file.client.folders['minecraft/mods'] = ['mc.liteloadermods']
    file.client.downloads.unshift liteloaderLib
    return BaseSanitizer.sanitize file
  end
end
