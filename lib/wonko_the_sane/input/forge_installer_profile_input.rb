class ForgeInstallerProfileInput < BaseInput
  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data, version)
    object = JSON.parse data, symbolize_names: true
    info = object[:versionInfo]
    file = WonkoVersion.new

    file.uid = @artifact
    file.version = version
    file.time = info[:time]
    file.type = info[:type]
    file.client.mainClass = info[:mainClass]
    file.client.minecraftArguments = info[:minecraftArguments]
    file.client.assets = info[:assets]
    file.requires << Referenced.new('net.minecraft', object[:install][:minecraft])
    libraries = info[:libraries].map { |obj| MojangInput.sanitize_mojang_library obj }.flatten 1
    file.client.downloads = libraries
    file.common.folders['minecraft/mods'] = ['mc.forgemods']
    file.common.folders['minecraft/mods'] << 'mc.forgecoremods' if object[:install][:minecraft].match /[^1]*1\.[0-6]/
    file.common.folders['minecraft/coremods'] = ['mc.forgecoremods'] if object[:install][:minecraft].match /[^1]*1\.[0-6]/
    file.server.downloads = libraries
    file.server.launchMethod = 'java.mainClass'
    file.server.extra[:forgeLibraryName] = %W(net.minecraftforge:forge:#{object[:install][:minecraft]}-#{version}:universal net.minecraftforge:forge:#{object[:install][:minecraft]}-#{version} net.minecraftforge:forge:#{version}:universal net.minecraftforge:forge:#{version} net.minecraftforge:minecraftforge:#{object[:install][:minecraft]}-#{version}:universal net.minecraftforge:minecraftforge:#{object[:install][:minecraft]}-#{version} net.minecraftforge:minecraftforge:#{version}:universal net.minecraftforge:minecraftforge:#{version})

    BaseSanitizer.sanitize file,
                           MojangExtractTweakersSanitizer,
                           MojangSplitLWJGLSanitizer,
                           ForgeRemoveMinecraftSanitizer,
                           ForgeFixJarSanitizer,
                           ForgePackXZUrlsSanitizer,
                           ForgeServerMainClassSanitizer
  end
end

class ForgeFixJarSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.client.downloads.map! do |lib|
      ident = WonkoTheSane::Util::MavenIdentifier.new(lib.name)
      ident.artifact = 'forge' if 'net.minecraftforge' == ident.group && 'minecraftforge' == ident.artifact
      if %w(forge fml).include?(ident.artifact) && %w(net.minecraftforge cpw.mods).include?(ident.group)
        mcversion = file.requires.find { |r| r.uid == 'net.minecraft' }.version rescue nil
        lib = lib.clone
        ident.classifier = 'universal'
        ident.version = "#{mcversion}-#{ident.version}" unless ident.version.start_with? "#{mcversion}"
        lib.name = ident.to_name
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
    mcversion = file.requires.find { |r| r.uid == 'net.minecraft' }.version rescue nil

    minecraft = Registry.instance.retrieve 'net.minecraft', mcversion
    if minecraft.nil?
      # if we can't find the wanted version on the first try we try reloading the list to see if we get something
      WonkoTheSane.lists.find { |l| l.artifact == 'net.minecraft' }.refresh
      minecraft = Registry.instance.retrieve 'net.minecraft', mcversion
    end

    if minecraft
      file.client.mainClass = nil if minecraft.client.mainClass == file.client.mainClass
      file.client.minecraftArguments = nil if minecraft.client.minecraftArguments == file.client.minecraftArguments
      file.client.assets = nil if minecraft.client.assets == file.client.assets
      file.client.downloads.reject! do |lib|
        minecraft.client.downloads.find { |mcLib| lib.name == mcLib.name } != nil
      end
      file.requires.reject! do |req|
        minecraft.requires.find { |mcReq| req == mcReq } != nil
      end
    else
      # don't know which version of minecraft this is, so we can't know which parts to eliminate
    end

    file
  end
end

class ForgePackXZUrlsSanitizer < BaseSanitizer
  class << self; attr_accessor :pack_xz_libs; end
  self.pack_xz_libs = ['org.scala-lang', 'com.typesafe', 'com.typesafe.akka']

  def self.sanitize(file)
    file.client.downloads.map! do |lib|
      if self.pack_xz_libs.include? WonkoTheSane::Util::MavenIdentifier.new(lib.name).group
        lib.maven_base_url = 'http://repo.spongepowered.org/maven/'
      end
      lib
    end
    file
  end
end

class ForgeServerMainClassSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.server.downloads.each do |download|
      if file.server.extra[:forgeLibraryName].include? download.name
        lib_file = HTTPCache.file(download.usable_url, ctxt: file.uid, check_stale: false)
        # Handle entries one by one
        text = ExtractionCache.get(lib_file, :zip, 'META-INF/MANIFEST.MF')
        match =  text.lines.find { |l| l.match /Main-Class: (.*)/ }
        file.server.mainClass = match[1] unless match.nil?
      end
    end
    file
  end
end
