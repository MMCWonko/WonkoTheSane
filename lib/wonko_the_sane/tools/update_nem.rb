def get_curse_id(name)
  data = HTTPCache.get('http://minecraft.curseforge.com/mc-mods/' + name).gsub /[\n\r]/, ''
  match = data.match /<li class="view-on?-cur?se"> *<a href="http:\/\/curse.com\/project\/(\d*)">/
  match[1]
end

def update_nem
  self.forgefiles_cleaned = {
    IronChests: :IronChests2
  }

  sources = WonkoTheSane.data_json 'sources.json'
  sources[:forgefiles] = {} unless sources[:forgefiles]
  sources[:jenkins] = [] unless sources[:jenkins]
  sources[:curse] = [] unless sources[:curse]

  nem_list = JSON.parse HTTPCache.get('https://raw.githubusercontent.com/SinZ163/NotEnoughMods/master/NEMP/mods.json'), symbolize_names: true
  nem_list.each do |key, value|
    name = (value[:name] ? value[:name] : key).to_sym
    case value[:function]
    when 'CheckMCForge2'
      if self.forgefiles_cleaned[name]
        name = self.forgefiles_cleaned[name]
      end
      if not sources[:forgefiles].find do |artifact, urlId| urlId == name.to_s end and not [:MinecraftForge, :FML, :Cauldron].include? name
        print "Please enter an uid for the #{"forgefiles".cyan} artifact #{name.to_s.green}: "
        uid = gets.chomp
        unless uid.empty?
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
      curse_id = value[:curse][:id] ? value[:curse][:id] : get_curse_id(value[:curse][:name] ? value[:curse][:name] : name.to_s.downcase)
      if sources[:curse].find { |obj| obj[:id] == curse_id }.nil?
        print "Please enter an uid for the #{'curse'.cyan} artifact #{name.to_s.green} (id: #{curse_id.yellow}): "
        uid = gets.chomp
        unless uid.empty?
          sources[:curse] << {
            uid: uid,
            id: curse_id,
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
      parts = value[:jenkins][:url].match /^(.*)\/job\/([^\/]*)\//
      if sources[:jenkins].find { |obj| obj[:url] == parts[1] && obj[:artifact] == parts[2] }.nil?
        print "Please enter an uid for the #{"jenkins".cyan} artifact #{name.to_s.green} from #{parts[1].yellow} (#{parts[2].red}): "
        uid = gets.chomp
        unless uid.empty?
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
    else
      print 'Unknown checker function: ' + value[:function]
    end

    # keep the writing in the loop so we don't lose progress in case of crashes or similar
    WonkoTheSane.set_data_json 'sources.json', sources
  end
end
