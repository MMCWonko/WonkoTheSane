class JenkinsInput < BaseInput
  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data)
    if data[:result] != 'SUCCESS'
      return nil
    end

    file = Version.new

    file.uid = @artifact
    file.version = data[:number].to_s
    file.time = data[:timestamp]

    artifact = data[:artifacts].find do |art|
      path = art[:displayPath]
      not path.include? '-api.' and not path.include? '-deobf.' and not path.include? '-dev.' and not path.include? '-javadoc.' and not path.include? '-library.' and not path.include? '-sources.' and not path.include? '-src.' and not path.include? '-util.'
    end

    if not artifact
      puts 'no valid artifact found for ' + @artifact + ' version ' + file.version
    else
      dl = FileDownload.new
      dl.destination = "mods/#{file.uid}-#{file.version}.jar"
      dl.url = "#{data[:url]}/artifact/#{artifact[:relativePath]}"
      file.downloads << dl
    end

    return BaseSanitizer.sanitize file
  end
end
