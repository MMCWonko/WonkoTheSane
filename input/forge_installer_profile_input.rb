require_relative '../base_input'

class ForgeInstallerProfileInput < BaseInput
  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data, version)
    object = JSON.parse data, symbolize_names: true
    info = object[:versionInfo]
    file = Version.new

    file.uid = @artifact
    file.version = version
    file.time = info[:time]
    file.type = info[:type]
    file.mainClass = info[:mainClass]
    file.minecraftArguments = info[:minecraftArguments]
    file.assets = info[:assets]
    file.requires << Referenced.new('net.minecraft', object[:install][:minecraft])
    file.libraries = info[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end

    return BaseSanitizer.sanitize file, MojangExtractTweakersSanitizer, MojangSplitLWJGLSanitizer, ForgeRemoveMinecraftSanitizer, ForgeFixJarSanitizer, ForgePackXZUrlsSanitizer
  end
end

class ForgeFixJarSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.libraries.map! do |lib|
      ident = MavenIdentifier.new(lib.name)
      if 'net.minecraftforge' == ident.group && 'forge' == ident.artifact
        lib = lib.clone
        ident.classifier = 'universal'
        lib.name = ident.to_name()
      end
      lib
    end
    file
  end
end

# Removes minecraft stuff (libraries, arguments etc.)
class ForgeRemoveMinecraftSanitizer < BaseSanitizer
  def self.sanitize(file)
    return nil if file.uid == 'org.lwjgl' # remove lwjgl, it's managed by minecraft
    return file if file.uid != 'net.minecraftforge'
    mcversion = nil
    file.requires.each do |req|
      if req.uid == 'net.minecraft'
        mcversion = req.version
      end
    end
    minecraft = $registry.retrieve 'net.minecraft', mcversion
    if not minecraft
      # if we can't find the wanted version on the first try we try reloading the list to see if we get something
      $vanilla.refresh
      minecraft = $registry.retrieve 'net.minecraft', mcversion
    end
    if minecraft
      file.mainClass = nil if minecraft.mainClass == file.mainClass
      file.minecraftArguments = nil if minecraft.minecraftArguments == file.minecraftArguments
      file.assets = nil if minecraft.assets == file.assets
      file.libraries.select! do |lib|
        nil == minecraft.libraries.find do |mcLib|
          lib.name == mcLib.name
        end
      end
      file.requires.select! do |req|
        if minecraft.requires
          nil == minecraft.requires.find do |mcReq|
            req == mcReq
          end
        else
          true
        end
      end
    else
      # don't know which version of minecraft this is, so we can't know which parts to eliminate
    end
    file
  end
end

class ForgePackXZUrlsSanitizer < BaseSanitizer
  @@packXZLibs = [ 'org.scala-lang', 'com.typesafe', 'com.typesafe.akka' ]
  def self.sanitize(file)
    file.libraries.map! do |lib|
      if @@packXZLibs.include? MavenIdentifier.new(lib.name).group
        lib = lib.clone
        lib.url = 'http://repo.spongepowered.org/maven/'
      end
      lib
    end
    file
  end
end