require_relative '../base_input'

class MojangInput
  # reads a general mojang-style library
  # TODO os versions
  def self.sanetize_mojang_library(object)
    if object.key? :natives
      lib = VersionNative.new
    else
      lib = VersionLibrary.new
    end
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
    file = VersionFile.new

    file.id = @artifact
    file.version = object[:id]
    file.time = object[:time]
    file.type = object[:type]
    file.mainClass = object[:mainClass]
    file.assets = object[:assets]
    file.minecraftArguments = object[:minecraftArguments]
    file.libraries = object[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end

    return BaseSanitizer.sanitize file, MojangSplitNativesSanitizer, MojangSplitLWJGLSanitizer
  end
end

class MojangSplitNativesSanitizer < BaseSanitizer
  def self.sanitize(file)
    libs = []
    natives = []
    file.libraries.each do |lib|
      if lib.is_a? VersionNative
        natives << lib
      else
        libs << lib
      end
    end
    file.libraries = libs
    file.natives = natives
    return file
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
    lwjgl = VersionFile.new
    lwjgl.id = 'org.lwjgl'
    lwjgl.libraries = []
    lwjgl.natives = []
    file.libraries.select! do |lib|
      if lib.name.include? @@lwjglMaster
        lwjgl.version = MavenIdentifier.new(lib.name).version
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
    file.natives.select! do |nat|
      nil == @@lwjglList.find do |lwjglCandidate|
        if nat.name.include? lwjglCandidate
          lwjgl.natives << nat
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