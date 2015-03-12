require_relative '../base_input'

class MojangInput
  # reads a general mojang-style library
  # TODO os versions
  def self.sanetize_mojang_library(object)
    lib = if object.key? :natives then VersionLibraryNative.new else VersionLibrary.new end
    lib.name = object[:name]
    lib.mavenBaseUrl = object.key?(:url) ? object[:url] : 'https://libraries.minecraft.net/'

    allowed = VersionLibrary.possiblePlatforms
    if object.key? :rules
      object[:rules].each do |rule|
        if rule[:action] == 'allow'
          if rule.key? :os and rule[:os].key? :name
            if rule[:os][:name] == 'windows'
              allowed << 'win32'
              allowed << 'win64'
            elsif rule[:os][:name] == 'linux'
              allowed << 'lin32'
              allowed << 'lin64'
            elsif rule[:os][:name] == 'osx'
              allowed << 'osx64'
            end
          else
            allowed = VersionLibrary.possiblePlatforms
          end
        elsif rule[:action] == 'disallow'
          if rule.key? :os and rule[:os].key? :name
            if rule[:os][:name] == 'windows'
              allowed.delete 'win32'
              allowed.delete 'win64'
            elsif rule[:os][:name] == 'linux'
              allowed.delete 'lin32'
              allowed.delete 'lin64'
            elsif rule[:os][:name] == 'osx'
              allowed.delete 'osx64'
            end
          else
            allowed = []
          end
        end
      end
    end

    libs = []
    if not lib.is_a? VersionLibraryNative
      lib.platforms = allowed.uniq
      libs << lib
    else
      nativeIds = {}
      if object.key? :natives
        natives = object[:natives]
        if natives.key? :windows
          nativeIds['win32'] = natives[:windows].gsub "${arch}", '32'
          nativeIds['win64'] = natives[:windows].gsub "${arch}", '64'
        end
        if natives.key? :linux
          nativeIds['lin32'] = natives[:linux].gsub "${arch}", '32'
          nativeIds['lin64'] = natives[:linux].gsub "${arch}", '64'
        end
        if natives.key? :osx
          nativeIds['osx64'] = natives[:osx].gsub "${arch}", '64'
        end
      end

      allowed.uniq.each do |platform|
        if not nativeIds.key? platform
          next
        end

        native = lib.clone
        native.platforms = [platform]
        native.url = native.url.sub '.jar', ('-' + nativeIds[platform] + '.jar')
        libs << native
      end
    end

    return libs
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
    file.client.mainClass = object[:mainClass]
    file.client.assets = object[:assets]
    file.client.minecraftArguments = object[:minecraftArguments]
    file.client.downloads = object[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end.flatten 1
    mainLib = VersionLibrary.new
    mainLib.name = 'net.minecraft:minecraft:' + file.version
    mainLib.url = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/' + file.version + '.jar'
    file.client.downloads << mainLib
    file.server.serverLib = VersionLibrary.new
    file.server.serverLib.name = 'net.minecraft:minecraft_server:' + file.version
    file.server.serverLib.url = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/minecraft_server.' + file.version + '.jar'

    file.client.folders['minecraft/screenshots'] = ['general.screenshots']
    file.client.folders['minecraft/resourcepackks'] = ['mc.resourcepacks'] if file.time >= 1372430921
    file.client.folders['minecraft/texturepacks'] = ['mc.texturepacks'] if file.time < 1372430921
    file.client.folders['minecraft/saves'] = ['mc.saves.anvil'] if file.time >= 1330552800
    file.client.folders['minecraft/saves'] = ['mc.saves.region'] if file.time >= 1298325600 and file.time < 1330552800
    file.client.folders['minecraft/saves'] = ['mc.saves.infdev'] if file.time >= 1291327200 and file.time < 1298325600

    return BaseSanitizer.sanitize file, MojangSplitLWJGLSanitizer
  end
end

class MojangExtractTweakersSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.client.tweakers = file.client.minecraftArguments.scan(/--tweakClass ([^ ]*)/).flatten
    file.client.minecraftArguments = file.client.minecraftArguments.gsub /\ ?--tweakClass ([^ ]*)/, ''
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
    lwjgl.type = 'release'
    file.client.downloads.select! do |lib|
      if lib.name.include? @@lwjglMaster
        lwjgl.version = MavenIdentifier.new(lib.name).version
        lwjgl.time = nil
      end
      nil == @@lwjglList.find do |lwjglCandidate|
        if lib.name.include? lwjglCandidate
          lwjgl.client.downloads << lib
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
    if file.client.extra[:processArguments]
      case file.client.extra[:processArguments]
        when 'legacy'
          file.client.minecraftArguments = ' ${auth_player_name} ${auth_session}'
        when 'username_session'
          file.client.minecraftArguments = '--username ${auth_player_name} --session ${auth_session}'
        when 'username_session_version'
          file.client.minecraftArguments = '--username ${auth_player_name} --session ${auth_session} --version ${profile_name}'
      end
      file.client.extra.delete :processArguments
    end
    file
  end
end
