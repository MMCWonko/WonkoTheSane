require 'json'
require_relative '../base_input'
require 'pry'

class ForgeInstallerProfileInput < BaseInput
  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data, version)
    object = JSON.parse data, symbolize_names: true
    info = object[:versionInfo]
    file = VersionFile.new

    file.id = @artifact
    file.version = version
    file.time = info[:time]
    file.type = info[:type]
    file.mainClass = info[:mainClass]
    file.minecraftArguments = info[:minecraftArguments]
    file.assets = info[:assets]
    file.requires = ['net.minecraft:' + object[:install][:minecraft]]
    file.libraries = info[:libraries].map do |obj|
      MojangInput.sanetize_mojang_library obj
    end

    return BaseSanitizer.sanitize file, MojangSplitNativesSanitizer, MojangExtractTweakersSanitizer, MojangSplitLWJGLSanitizer, ForgeRemoveMinecraftSanitizer
  end
end

# Removes minecraft stuff (libraries, arguments etc.)
class ForgeRemoveMinecraftSanitizer < BaseSanitizer
  def self.sanitize(file)
    return file if file.id != 'net.minecraftforge'
    mcversion = nil
    file.requires.each do |req|
      if req.include? 'net.minecraft:'
        mcversion = req.sub 'net.minecraft:', ''
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
      file.natives.select! do |nat|
        nil == minecraft.natives.find do |mcNat|
          nat.name == mcNat.name
        end
      end
      file.requires.select! do |req|
        nil == minecraft.requires.find do |mcReq|
          req == mcReq
        end
      end
    else
      # don't know which version of minecraft this is, so we can't know which parts to eliminate
    end
    file
  end
end