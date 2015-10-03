def allowed_platforms_for_rules(rules)
  possible = ['win32', 'win64', 'lin32', 'lin64', 'osx64']

  allowed = possible
  if rules
    rules.each do |rule|
      if rule.is_a? ImplicitRule
        if rule.action == :allow
          allowed = possible
        else
          allowed = []
        end
      elsif rule.is_a? OsRule
        if rule.action == :allow
          case rule.os
          when 'windows'
            allowed << 'win32' << 'win64'
          when 'linux'
            allowed << 'lin32' << 'lin64'
          when 'osx'
            allowed << 'osx64'
          end
        elsif rule.action == :disallow
          case rule.os
          when 'windows'
            allowed.delete 'win32'
            allowed.delete 'win64'
          when 'linux'
            allowed.delete 'lin32'
            allowed.delete 'lin64'
          when 'osx'
            allowed.delete 'osx64'
          end
        end
      end
    end
  end

  allowed
end

class MojangInput
  # reads a general mojang-style library
  def self.sanitize_mojang_library(object)
    lib = object.key?(:natives) ? VersionLibraryNative.new : VersionLibrary.new
    lib.name = object[:name]
    lib.maven_base_url = object.key?(:url) ? object[:url] : 'https://libraries.minecraft.net/'
    lib.rules = object[:rules].map do |obj| Rule.from_json obj end if object[:rules]

    libs = []
    if !lib.is_a? VersionLibraryNative
      libs << lib
    else
      native_ids = {}
      natives = object[:natives]
      if natives.key? :windows
        native_ids['win32'] = natives[:windows].gsub "${arch}", '32'
        native_ids['win64'] = natives[:windows].gsub "${arch}", '64'
      end
      if natives.key? :linux
        native_ids['lin32'] = natives[:linux].gsub "${arch}", '32'
        native_ids['lin64'] = natives[:linux].gsub "${arch}", '64'
      end
      if natives.key? :osx
        native_ids['osx64'] = natives[:osx].gsub "${arch}", '64'
      end

      allowed_platforms_for_rules(lib.rules).uniq.each do |platform|
        next unless native_ids.key? platform

        native = lib.clone
        native.rules = [
          ImplicitRule.new(:disallow),
          OsRule.new(:allow,
          {'win32': :windows, 'win64': :windows, 'lin32': :linux, 'lin64': :linux, 'osx64': :osx}[platform.to_sym],
          nil,
          {'win32': '32', 'win64': '64', 'lin32': '32', 'lin64': '64', 'osx64': '64'}[platform.to_sym])
        ]
        native.url = native.url.sub '.jar', ('-' + native_ids[platform] + '.jar')
        libs << native
      end
    end

    libs
  end

  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data)
    object = data.class == Hash ? data : JSON.parse(data, symbolize_names: true)

    if object[:minimumLauncherVersion] and object[:minimumLauncherVersion] > 14
      logger.warn 'To high minimumLauncherVersion encountered for ' + object[:id] + ': ' + object[:minimumLauncherVersion]
      return []
    end

    file = WonkoVersion.new

    file.uid = @artifact
    file.version = object[:id]
    file.time = object[:releaseTime]
    file.type = object[:type]
    file.client.mainClass = object[:mainClass]
    file.client.assets = object[:assets]
    file.client.minecraftArguments = object[:minecraftArguments]
    file.client.jarModTarget = "net.minecraft:minecraft:#{file.version}"
    file.client.downloads = object[:libraries].map { |obj| MojangInput.sanitize_mojang_library obj }.flatten 1
    main_lib = VersionLibrary.new
    main_lib.name = "net.minecraft:minecraft:#{file.version}"
    main_lib.url = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/' + file.version + '.jar'
    file.client.downloads << main_lib
    file.client.launchMethod = 'minecraft'

    server_lib = VersionLibrary.new
    server_lib.name = "net.minecraft:minecraft_server:#{file.version}"
    server_lib.url = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + file.version + '/minecraft_server.' + file.version + '.jar'
    file.server.downloads << server_lib
    file.server.jarModTarget = "net.minecraft:minecraft_server:#{file.version}"
    file.server.launchMethod = 'java.jar'

    file.client.folders['minecraft/screenshots'] = ['general.screenshots']
    file.client.folders['minecraft/resourcepackks'] = ['mc.resourcepacks'] if file.time >= 1372430921
    file.client.folders['minecraft/texturepacks'] = ['mc.texturepacks'] if file.time < 1372430921
    file.client.folders['minecraft/saves'] = ['mc.saves.anvil'] if file.time >= 1330552800
    file.client.folders['minecraft/saves'] = ['mc.saves.region'] if file.time >= 1298325600 and file.time < 1330552800
    file.client.folders['minecraft/saves'] = ['mc.saves.infdev'] if file.time >= 1291327200 and file.time < 1298325600

    BaseSanitizer.sanitize file, MojangSplitLWJGLSanitizer
  end
end

class MojangExtractTweakersSanitizer < BaseSanitizer
  def self.sanitize(file)
    file.client.tweakers = file.client.minecraftArguments.scan(/--tweakClass ([^ ]*)/).flatten
    file.client.minecraftArguments = file.client.minecraftArguments.gsub /\ ?--tweakClass ([^ ]*)/, ''
    file
  end
end

# extract lwjgl specific libraries and natives
class MojangSplitLWJGLSanitizer < BaseSanitizer
  class << self; attr_accessor :lwjgl_list, :lwjgl_extras; end
  self.lwjgl_list = %w(org.lwjgl net.java.jinput net.java.jutils)
  self.lwjgl_extras = %w(net.java.jinput net.java.jutils)

  def self.sanitize(file)
    file.requires = [] if file.requires.nil?
    file.requires << Referenced.new('org.lwjgl')

    extras = [] # [Download]
    versioned = Hash.new { |hash, key| hash[key] = [] } # String => [Download]
    file.client.downloads.select! do |lib|
      nil == self.lwjgl_list.find do |lwjgl_candidate|
        if lib.name.include? lwjgl_candidate
          if self.lwjgl_extras.include? lib.maven.group
            extras << lib
          else
            versioned[lib.maven.version] << lib
          end
          true
        else
          false
        end
      end
    end

    files = [file]
    versioned.each do |version, downloads|
      lwjgl = WonkoVersion.new
      lwjgl.uid = 'org.lwjgl'
      lwjgl.type = 'release'
      lwjgl.version = version
      lwjgl.time = nil # re-fetches the time for the version from storage
      lwjgl.client.downloads = extras + downloads
      files << lwjgl
    end

    return files
  end
end

class MojangTraitsSanitizer < BaseSanitizer
  def self.sanitize(file)
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
