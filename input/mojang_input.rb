require_relative '../base_input'

class MojangInput
  # reads a general mojang-style library
  # TODO os versions
  def self.sanetize_mojang_library(object)
    lib = VersionLibrary.new
    lib.name = object[:name]
    lib.url = object.key?(:url) ? object[:url] : 'https://libraries.minecraft.net/'

    allowed = VersionLibrary.possiblePlatforms
    if object.key? :rules
      object[:rules].each do |rule|
        if rule[:action] == :allow
          if rule.key? :os
            if rule[:os] == 'windows'
              allowed << 'win32'
              allowed << 'win64'
            elsif rules[:os] == 'linux'
              allowed << 'lin32'
              allowed << 'lin64'
            elsif rules[:os] == 'osx'
              allowed << 'osx'
            end
          else
            allowed = allowed + VersionLibrary.possiblePlatforms
          end
        elsif rule[:action] == :disallow
          if rule.key? :os
            if rule[:os] == 'windows'
              allowed.delete 'win32'
              allowed.delete 'win64'
            elsif rules[:os] == 'linux'
              allowed.delete 'lin32'
              allowed.delete 'lin64'
            elsif rules[:os] == 'osx'
              allowed.delete 'osx'
            end
          else
            allowed = []
          end
        end
      end
    end
    lib.platforms = allowed

    if object.key? :natives
      natives = object[:natives]
      lib.natives = {} unless lib.natives
      if natives.key? :windows
        lib.natives['win32'] = natives[:windows].gsub "${arch}", '32'
        lib.natives['win64'] = natives[:windows].gsub "${arch}", '64'
      end
      if natives.key? :linux
        lib.natives['lin32'] = natives[:linux].gsub "${arch}", '32'
        lib.natives['lin64'] = natives[:linux].gsub "${arch}", '64'
      end
      if natives.key? :osx
        lib.natives['osx64'] = natives[:osx].gsub "${arch}", '64'
      end
    end

    return lib
  end

  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data)
    object = data.class == Hash ? data : JSON.parse(data, symbolize_names: true)
    file = Version.new

    file.uid = @artifact
    file.versionId = object[:id]
    file.time = object[:releaseTime]
    file.type = object[:type]
    file.mainClass = object[:mainClass]
    file.assets = object[:assets]
    file.minecraftArguments = object[:minecraftArguments]
    file.libraries = object[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end

    return BaseSanitizer.sanitize file, MojangSnapshotVersionSanitizer, MojangSplitLWJGLSanitizer
  end
end

class MojangExtractTweakersSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.tweakers = file.minecraftArguments.scan(/--tweakClass ([^ ]*)/).flatten
    file.minecraftArguments = file.minecraftArguments.gsub /\ ?--tweakClass ([^ ]*)/, ''
    return file
  end
end

# extract lwjgl specific libraries and natives
class MojangSplitLWJGLSanitizer < BaseSanitizer
  @@lwjglList = ['org.lwjgl', 'net.java.jinput', 'net.java.jutils']
  @@lwjglMaster = 'org.lwjgl.lwjgl:lwjgl:'

  def self.sanitize(file)
    lwjgl = Version.new
    lwjgl.uid = 'org.lwjgl'
    lwjgl.libraries = []
    file.libraries.select! do |lib|
      if lib.name.include? @@lwjglMaster
        lwjgl.versionId = MavenIdentifier.new(lib.name).version
      end
      nil == @@lwjglList.find do |lwjglCandidate|
        if lib.name.include? lwjglCandidate
          lwjgl.libraries << lib
          true
        else
          false
        end
      end
    end
    file.requires = [] if file.requires.nil?
    file.requires << 'org.lwjgl'
    return [file, lwjgl]
  end
end

class MojangTraitsSanitizer < BaseSanitizer
  def self.sanitize(file)
    if file.uid == 'net.minecraft'
    end
    file
  end
end

class MojangProcessArgumentsSanitizer < BaseSanitizer
  def self.sanitize(file)
    if file.extra[:processArguments]
      case file.extra[:processArguments]
        when 'legacy'
          file.minecraftArguments = ' ${auth_player_name} ${auth_session}'
        when 'username_session'
          file.minecraftArguments = '--username ${auth_player_name} --session ${auth_session}'
        when 'username_session_version'
          file.minecraftArguments = '--username ${auth_player_name} --session ${auth_session} --version ${profile_name}'
      end
      file.extra.delete :processArguments
    end
    file
  end
end

class MojangSnapshotVersionSanitizer < BaseSanitizer
  @@mapping = {
      '14w02a' => '1.8-alpha1',
      '14w02b' => '1.8-alpha2',
      '14w02c' => '1.8-alpha3',
      '14w03a' => '1.8-alpha4',
      '14w03b' => '1.8-alpha5',
      '14w04a' => '1.8-alpha6',
      '14w04b' => '1.8-alpha7',
      '14w05a' => '1.8-alpha8',
      '14w05b' => '1.8-alpha9',
      '14w06a' => '1.8-alpha10',
      '14w06b' => '1.8-alpha11',
      '14w07a' => '1.8-alpha12',
      '14w08a' => '1.8-alpha13',
      '14w10a' => '1.8-alpha14',
      '14w10b' => '1.8-alpha15',
      '14w10c' => '1.8-alpha16',
      '14w11a' => '1.8-alpha17',
      '14w11b' => '1.8-alpha18',
      '14w17a' => '1.8-alpha19',
      '14w18a' => '1.8-alpha20',
      '14w18b' => '1.8-alpha21',
      '14w19a' => '1.8-alpha22',
      '14w20a' => '1.8-alpha23',
      '14w20b' => '1.8-alpha24',
      '14w21a' => '1.8-alpha25',
      '14w21b' => '1.8-alpha26',
      '14w25a' => '1.8-alpha27',
      '14w25b' => '1.8-alpha28',
      '14w26a' => '1.8-alpha29',
      '14w26b' => '1.8-alpha30',
      '14w26c' => '1.8-alpha31',
      '14w27a' => '1.8-alpha32',
      '14w27b' => '1.8-alpha33',
      '14w28a' => '1.8-alpha34',
      '14w28b' => '1.8-alpha35',
      '14w29a' => '1.8-alpha36',
      '14w29b' => '1.8-alpha37',
      '14w30a' => '1.8-alpha38',
      '14w30b' => '1.8-alpha39',
      '14w30c' => '1.8-alpha40',
      '14w31a' => '1.8-alpha41',
      '14w32a' => '1.8-alpha42',
      '14w32b' => '1.8-alpha43',
      '14w32c' => '1.8-alpha44',
      '14w32d' => '1.8-alpha45',
      '14w33a' => '1.8-alpha46',
      '14w33b' => '1.8-alpha47',
      '14w33c' => '1.8-alpha48',
      '14w34a' => '1.8-alpha49',
      '14w34b' => '1.8-alpha50',
      '14w34c' => '1.8-alpha51',
      '14w34d' => '1.8-alpha52'
  }

  def self.sanitize(file)
    if @@mapping.has_key? file.versionId
      file.versionName = file.versionId
      file.versionId = @@mapping[file.versionId]
    end
    return file
  end
end