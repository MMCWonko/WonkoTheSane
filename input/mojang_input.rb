require_relative '../base_input'

class MojangInput
  # reads a general mojang-style library
  # TODO os versions
  def self.sanetize_mojang_library(object)
    lib = VersionLibrary.new
    lib.name = object[:name]
    lib.url = object.key?(:url) ? object[:url] : 'https://libraries.minecraft.net/'
    lib.oldRules = object[:rules] if object.key? :rules
    lib.oldNatives = object[:natives] if object.key? :natives

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

    if object[:minimumLauncherVersion] and object[:minimumLauncherVersion] > 14
      # TODO log error
      return []
    end

    file = Version.new

    file.uid = @artifact
    file.version = object[:id]
    file.time = object[:releaseTime]
    file.type = object[:type]
    file.mainClass = object[:mainClass]
    file.assets = object[:assets]
    file.minecraftArguments = object[:minecraftArguments]
    file.libraries = object[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end
    file.mainLib = VersionLibrary.new
    file.mainLib.name = 'net.minecraft:minecraft:' + file.version
    file.mainLib.absoluteUrl = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/' + file.version + '.jar'

    return BaseSanitizer.sanitize file, MojangSplitLWJGLSanitizer
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
        lwjgl.version = MavenIdentifier.new(lib.name).version
        lwjgl.time = nil
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
    file.requires << Referenced.new('org.lwjgl')
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
