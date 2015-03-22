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
    file.client.mainClass = info[:mainClass]
    file.client.minecraftArguments = info[:minecraftArguments]
    file.client.assets = info[:assets]
    file.requires << Referenced.new('net.minecraft', object[:install][:minecraft])
    libraries = info[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end.flatten 1
    file.client.downloads = libraries
    file.client.folders['minecraft/mods'] = ['mc.forgemods']
    file.client.folders['minecraft/mods'] << 'mc.forgecoremods' if object[:install][:minecraft].match /[^1]*1\.[0-6]/
    file.client.folders['minecraft/coremods'] = ['mc.forgecoremods'] if object[:install][:minecraft].match /[^1]*1\.[0-6]/
    file.server.folders['minecraft/mods'] = ['mc.forgemods']
    file.server.folders['minecraft/mods'] << 'mc.forgecoremods' if object[:install][:minecraft].match /[^1]*1\.[0-6]/
    file.server.folders['minecraft/coremods'] = ['mc.forgecoremods'] if object[:install][:minecraft].match /[^1]*1\.[0-6]/
    file.server.downloads = libraries
    file.server.launchMethod = 'java.mainClass'
    file.server.extra[:forgeLibraryName] = %W(net.minecraftforge:forge:#{object[:install][:minecraft]}-#{version}:universal net.minecraftforge:forge:#{object[:install][:minecraft]}-#{version})

    return BaseSanitizer.sanitize file, MojangExtractTweakersSanitizer, MojangSplitLWJGLSanitizer, ForgeRemoveMinecraftSanitizer, ForgeFixJarSanitizer, ForgePackXZUrlsSanitizer, ForgeServerMainClassSanitizer
  end
end

class ForgeFixJarSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.client.downloads.map! do |lib|
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
      $globalLists.each do |list|
        list.refresh if list.artifact == 'net.minecraft'
      end
      minecraft = $registry.retrieve 'net.minecraft', mcversion
    end
    if minecraft
      file.client.mainClass = nil if minecraft.client.mainClass == file.client.mainClass
      file.client.minecraftArguments = nil if minecraft.client.minecraftArguments == file.client.minecraftArguments
      file.client.assets = nil if minecraft.client.assets == file.client.assets
      file.client.downloads.select! do |lib|
        nil == minecraft.client.downloads.find do |mcLib|
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
  @@packXZLibs = ['org.scala-lang', 'com.typesafe', 'com.typesafe.akka']

  def self.sanitize(file)
    file.client.downloads.map! do |lib|
      if @@packXZLibs.include? MavenIdentifier.new(lib.name).group
        lib = lib.clone
        lib.mavenBaseUrl = 'http://repo.spongepowered.org/maven/'
      end
      lib
    end
    file
  end
end

class ForgeServerMainClassSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.server.downloads.map! do |download|
      if file.server.extra[:forgeLibraryName].include? download.name
        url = download.internalUrl ? download.internalUrl : download.url
        libFile = HTTPCatcher.file url
        Zip::File.open(libFile) do |zip_file|
          # Handle entries one by one
          text = zip_file.read 'META-INF/MANIFEST.MF'
          lines = text.lines('\n')
          lines.each do |l|
            if (m = (l =~ /Main-Class: (.*)/))
              file.server.mainClass = m[1]
              break
            end
          end
        end
      end
      download
    end
    file
  end
end
