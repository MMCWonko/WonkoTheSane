class ForgeFilesModsInput < BaseInput
  def parse(data, version)
    file = WonkoVersion.new

    file.uid = @uid
    file.name = @name
    file.version = version
    file.time = data[:info]
    file.requires << Referenced.new('net.minecraft', data[:mcver])

    f = data[:files].find { |f| %w(jar zip).include?(f[:ext]) && %(universal client main).include?(f[:buildtype].downcase) }
    if f.nil?
      logger.warn 'No file found for ' + file.uid + ' version ' + file.version
      return []
    end

    dl = FileDownload.new
    dl.url = f[:url]
    dl.destination = "mods/#{file.uid}-#{file.version}.jar"
    file.common.downloads << dl

    BaseSanitizer.sanitize file
  end
end
