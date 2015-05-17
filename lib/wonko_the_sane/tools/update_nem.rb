def get_curse_id(name)
  data = HTTPCatcher.get('http://minecraft.curseforge.com/mc-mods/' + name).gsub /[\n\r]/, ''
  match = data.match /<li class="view-on?-cur?se"> *<a href="http:\/\/curse.com\/project\/(\d*)">/
  return match[1]
end

def update_nem
  forgefilesCleaned = {
    IronChests: :IronChests2
  }

  sources = WonkoTheSane.data_json 'sources.json'
  sources[:forgefiles] = {} if not sources[:forgefiles]
  sources[:jenkins] = [] if not sources[:jenkins]
  sources[:curse] = [] if not sources[:curse]

  nemList = JSON.parse HTTPCatcher.get('https://raw.githubusercontent.com/SinZ163/NotEnoughMods/master/NEMP/mods.json'), symbolize_names: true
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
      curseId = value[:curse][:id] ? value[:curse][:id] : get_curse_id(value[:curse][:name] ? value[:curse][:name] : name.to_s.downcase)
      if not sources[:curse].find do |obj| obj[:id] == curseId end
        print "Please enter an uid for the #{"curse".cyan} artifact #{name.to_s.green} (id: #{curseId.yellow}): "
        uid = gets.chomp
        if not uid.empty?
          sources[:curse] << {
            uid: uid,
            id: curseId,
            fileregex: value[:curse][:regex]
          }
        end
      end
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

    # keep the writing in the loop so we don't lose progress in case of crashes or similar
    WonkoTheSane.set_data_json 'sources.json', sources
  end
end
