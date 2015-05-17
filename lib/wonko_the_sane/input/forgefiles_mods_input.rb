class ForgeFilesModsInput < BaseInput
  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data, version)
    file = WonkoVersion.new

    file.uid = @artifact
    file.version = version
    file.time = data[:info]

    f = data[:files].find do |file|
      type = file[:buildtype].downcase
      (file[:ext] == 'jar' or file[:ext] == 'zip') and (type == 'universal' or type == 'client' or type == 'main') #not type.include? 'src' and not type.include? 'deobf' and not type.include? 'api' and not type.include? 'backup'
    end
    if not f
      logger.warn 'No file found for ' + file.uid + ' version ' + file.version
      return []
    end
    file.requires << Referenced.new('net.minecraft', f[:mcver])

    dl = FileDownload.new
    dl.url = f[:url]
    dl.destination = "mods/#{file.uid}-#{file.version}.jar"
    file.common.downloads << dl

    return BaseSanitizer.sanitize file
  end
end
