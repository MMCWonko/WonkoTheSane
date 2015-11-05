require_relative 'base_version_list'

def fml_libs_mappings
  def create_fmllib_download(file, forge_has = true)
    forge_base_url = 'http://files.minecraftforge.net/fmllibs/'
    multimc_base_url = 'http://files.multimc.org/fmllibs/'

    FileDownload.new (forge_has ? forge_base_url : multimc_base_url) + file, 'minecraft/lib/' + file
  end

  libs14 = [
      create_fmllib_download('argo-2.25.jar'),
      create_fmllib_download('guava-12.0.1.jar'),
      create_fmllib_download('asm-all-4.0.jar'),
      create_fmllib_download('bcprov-jdk15on-147.jar')
  ]

  {
      :'1.3.2' => [
          create_fmllib_download('argo-2.25.jar'),
          create_fmllib_download('guava-12.0.1.jar'),
          create_fmllib_download('asm-all-4.0.jar')
      ],
      :'1.4' => libs14,
      :'1.4.1' => libs14,
      :'1.4.2' => libs14,
      :'1.4.3' => libs14,
      :'1.4.4' => libs14,
      :'1.4.5' => libs14,
      :'1.4.6' => libs14,
      :'1.4.7' => libs14,
      :'1.5' => [
        create_fmllib_download('argo-small-3.2.jar'),
        create_fmllib_download('guava-14.0-rc3.jar'),
        create_fmllib_download('asm-all-4.1.jar'),
        create_fmllib_download('bcprov-jdk15on-148.jar', false),
        create_fmllib_download('deobfuscation_data_1.5.zip'),
        create_fmllib_download('scala-library.jar', false)
      ],
      :'1.5.1' => [
          create_fmllib_download('argo-small-3.2.jar'),
          create_fmllib_download('guava-14.0-rc3.jar'),
          create_fmllib_download('asm-all-4.1.jar'),
          create_fmllib_download('bcprov-jdk15on-148.jar', false),
          create_fmllib_download('deobfuscation_data_1.5.1.zip'),
          create_fmllib_download('scala-library.jar', false)
      ],
      :'1.5.2' => [
          create_fmllib_download('argo-small-3.2.jar'),
          create_fmllib_download('guava-14.0-rc3.jar'),
          create_fmllib_download('asm-all-4.1.jar'),
          create_fmllib_download('bcprov-jdk15on-148.jar', false),
          create_fmllib_download('deobfuscation_data_1.5.2.zip'),
          create_fmllib_download('scala-library.jar', false)
      ]
  }
end

class ForgeVersionList < BaseVersionList
  def initialize(uid = 'net.minecraftforge', name = 'Minecraft Forge', url_id = 'forge')
    super(uid, name)
    @input = ForgeInstallerProfileInput.new uid, name
    @url_id = url_id
  end

  def get_versions
    result = get_json "http://files.minecraftforge.net/maven/net/minecraftforge/#{@url_id}/json"

    out = {}
    result[:number].values.each do |obj|
      out[obj[:build]] = obj.merge({
        artifact: result[:artifact],
        baseurl: result[:webpath]
      })
    end
    out
  end

  def get_version(id)
    version = id[1][:mcversion] + '-' + id[1][:version]
    version += '-' + id[1][:branch] unless id[1][:branch].nil?

    result = []

    files = id[1][:files]
    installer_file = files.find { |file| file[1] == 'installer' }
    universal_file = files.find { |file| file[1] == 'universal' }
    client_file = files.find { |file| file[1] == 'client' }
    server_file = files.find { |file| file[1] == 'server' }

    # installer versions of forge
    if !installer_file.nil? && id[1][:mcversion] != '1.5.2'
      path = "#{version}/#{id[1][:artifact]}-#{version}-installer.#{installer_file[0]}"
      url = id[1][:baseurl] + '/' + path
      HTTPCache.get url, ctxt: @uid, key: 'forgeinstallers/' + path, check_stale: false
      result << @input.parse(ExtractionCache.get('cache/network/forgeinstallers/' + path, :zip, 'install_profile.json'), id[1][:version], id[1][:artifact])
    elsif !universal_file.nil?
      res = construct_base_version id[1]
      mod = Jarmod.new
      mod.name = "net.minecraftforge:#{id[1][:artifact]}:#{version}:universal@#{universal_file[0]}"
      mod.maven_base_url = 'http://files.minecraftforge.net/maven/'
      res.client.downloads << mod
      res.client.downloads |= fml_libs_mappings[id[1][:mcversion].to_sym] if fml_libs_mappings[id[1][:mcversion].to_sym]
      result << res
    elsif !client_file.nil?
      res = construct_base_version id[1]
      mod = Jarmod.new
      mod.name = "net.minecraftforge:#{id[1][:artifact]}:#{version}:client@#{client_file[0]}"
      mod.maven_base_url = 'http://files.minecraftforge.net/maven/'
      res.client.downloads << mod
      res.client.downloads |= fml_libs_mappings[id[1][:mcversion].to_sym] if fml_libs_mappings[id[1][:mcversion].to_sym]
      result << res
    elsif !server_file.nil?
      # TODO
    end
    result.flatten
  end

  def construct_base_version(data)
    version = WonkoVersion.new
    version.name = @name
    version.uid = @uid
    version.version = data[:version]
    version.requires << Referenced.new('net.minecraft', data[:mcversion])
    version.time = data[:modified]
    version.client.minecraftArguments = [
        '-Dfml.ignoreInvalidMinecraftCertificates=true', '-Dfml.ignorePatchDiscrepancies=true'
    ]
    version.common.folders['minecraft/mods'] = ['mc.forgemods']
    version.common.folders['minecraft/mods'] << 'mc.forgecoremods' if data[:mcversion].match /[^1]*1\.[0-6]/
    version.common.folders['minecraft/coremods'] = ['mc.forgecoremods'] if data[:mcversion].match /[^1]*1\.[0-6]/
    version
  end
end

class FMLVersionList < ForgeVersionList
  def initialize
    super 'net.minecraftforge.fml', 'Forge Mod Loader', 'fml'
  end
end
