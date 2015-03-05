require_relative 'util/cache'
require 'json'

def update_nem
  forgefilesCleaned = {
    IronChests: :IronChests2
  }

  sources = JSON.parse File.read('sources.json'), symbolize_names: true

  nemList = JSON.parse HTTPCatcher.get('https://raw.githubusercontent.com/SinZ163/NotEnoughMods/master/NEMP/mods.json', 'https://raw.githubusercontent.com/SinZ163/NotEnoughMods/master/NEMP/mods.json'), symbolize_names: true
  nemList.each do |key, value|
    name = (value[:name] ? value[:name] : key).to_sym
    case value[:function]
    when 'CheckMCForge2'
      if forgefilesCleaned[name]
        name = forgefilesCleaned[name]
      end
      if not sources[:forgefiles].find do |artifact, urlId| urlId == name.to_s end and not [:MinecraftForge, :FML, :Cauldron].include? name
        print "Please enter an uid for the #{"forgefiles".cyan} artifact #{name.to_s.green}: "
        uid = gets.chomp
        if not uid.empty?
          sources[:forgefiles][uid.to_sym] = name.to_s
        end
      end
    when 'CheckAE'
      # TODO
    when 'CheckAE2'
      # TODO
    when 'CheckAtomicStryker'
      # TODO
    when 'CheckBigReactors'
      # TODO
    when 'CheckBuildCraft'
      # TODO
    when 'CheckChickenBones'
      # TODO
    when 'CheckCurse'
      # TODO
    when 'CheckDropBox'
      # TODO
    when 'CheckGitHubRelease'
      # TODO
    when 'CheckHTML'
      # TODO
    when 'CheckJenkins'
      parts = value[:jenkins][:url].match(/^(.*)\/job\/([^\/]*)\//)
      if not sources[:jenkins].find do |obj| obj[:url] == parts[1] and obj[:artifact] == parts[2] end
        print "Please enter an uid for the #{"jenkins".cyan} artifact #{name.to_s.green} from #{parts[1].yellow} (#{parts[2].red}): "
        uid = gets.chomp
        if not uid.empty?
          sources[:jenkins] << {
            uid: uid,
            url: parts[1],
            artifact: parts[2]
          }
        end
      end
    when 'CheckLunatrius'
      # TODO
    when 'CheckSpacechase'
      # TODO
    end
  end

  File.write 'sources.json', JSON.pretty_generate(sources)
end
