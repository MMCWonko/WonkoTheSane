require 'time'

module OldFormatWriter
  def write_version(version)
    # metadata
    json = {
      formatVersion: 1,
      uid: version.uid,
      name: version.name,
      fileId: version.uid,
      version: version.version,
      time: Time.at(version.time).iso8601,
      releaseTime: Time.at(version.time).iso8601,
      type: version.type,
      requires: [],
      order: order_for(version.uid)
    }
    json[:requires] = version.requires.map do |req|
      obj = { uid: req.uid }
      obj[:version] = req.version if req.version
      obj
    end if version.requires and not version.requires.empty?
    json[:id] = version.version if version.uid == 'net.minecraft'

    resource = version.client

    vanilla_req = version.requires.find { |r| r.uid == 'net.minecraft' }

    json[:mainClass] = resource.mainClass if resource.mainClass && resource.mainClass != ''
    json[:appletClass] = resource.appletClass if resource.appletClass && resource.appletClass != ''
    json[:assets] = resource.assets if resource.assets && resource.assets != ''
    json[:mcVersion] = vanilla_req.version if vanilla_req
    json[:minecraftArguments] = resource.minecraftArguments

    vanilla = Registry.instance.retrieve 'net.minecraft', json[:mcVersion] if json[:mcVersion]

    json[:'+tweakers'] = resource.tweakers if resource.tweakers && !resource.tweakers.empty?

    natives = {}
    json[:'+libraries'] = resource.downloads
                            .select { |dl| dl.type == 'java.libraries' || dl.type == 'java.natives' }
                            .reject { |lib| lib.name.start_with? 'net.minecraft:minecraft:' }
                            .map do |lib|
      result = { name: lib.name }
      if lib.explicit_url?
        result[:'MMC-absoluteUrl'] = lib.url
      elsif !lib.url.nil? && lib.maven_base_url != 'https://libraries.minecraft.net/'
        result[:url] = lib.url
      end
      result[:rules] = lib.rules.map { |r| r.to_json } unless lib.rules.nil?

      if lib.name.include?('org.scala-lang') || lib.name.include?('com.typesafe')
        result[:'MMC-hint'] = 'forge-pack-xz'
      end

      in_vanilla = if vanilla
                     vanilla.client.downloads
                       .select { |dl| dl.type == 'java.libraries' || dl.type == 'java.natives' }
                       .find { |dl| dl.name == lib.name }
                   end
      if !in_vanilla.nil? && in_vanilla == lib
        # it's already there, no need to add it
      else
        if in_vanilla.nil?
          result[:insert] = 'append' unless version.uid == 'net.minecraft'
          if %w(minecraftforge forge fml liteloader).include? lib.maven.artifact
            result[:'MMC-depend'] = 'hard'
          end
        else
          result[:insert] = 'replace'
        end

        [lib, result]
      end
    end.reject { |i| i.nil? }.map do |array|
      lib = array[0]
      result = array[1]
      if lib.type == 'java.libraries'
        result
      else
        # reconstruct insane natives
        # mojang: you invented this fancy^Wweird rules system, and then you don't use it?
        natives[lib.name] ||= {}
        osrule = lib.rules[1]
        if natives[lib.name].key? osrule.os
          nil
        else
          natives[lib.name][osrule.os] = result
          result[:url] = result[:url].sub /(32|64)/, '${arch}' if result[:url]
          result[:'MMC-absoluteUrl'] = result[:'MMC-absoluteUrl'].sub /(32|64)/, '${arch}' if result[:'MMC-absoluteUrl']
          result[:rules][1][:os].delete :arch
          result
        end
      end
    end.reject { |i| i.nil? }

    json[:'+jarMods'] = resource.downloads.select { |dl| dl.type == 'mc.jarmods' }.map do |lib|
      {}
    end

    json
  end

  def order_for(uid)
    case uid
    when 'net.minecraftforge'
      5
    when 'com.mumfrey.liteloader'
      10
    when 'net.minecraft'
      -2
    when 'org.lwjgl'
      -1
    else
      0
    end
  end
end

class OldFormat
  include OldFormatWriter
end
$old_format = OldFormat.new
