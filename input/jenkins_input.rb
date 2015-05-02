class JenkinsInput < BaseInput
  def initialize(artifact, fileRegex)
    @artifact = artifact
    @fileRegex = fileRegex
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
      path = art[:fileName]
      if @fileRegex
        path.match @fileRegex
      else
        not path.include? '-api.' and not path.include? '-deobf.' and not path.include? '-dev.' and not path.include? '-javadoc.' and not path.include? '-library.' and not path.include? '-sources.' and not path.include? '-src.' and not path.include? '-util.'
      end
    end

    if not artifact
      logger.warn 'No valid artifact found for ' + file.version
    else
      dl = FileDownload.new
      dl.destination = "mods/#{file.uid}-#{file.version}.jar"
      dl.url = "#{clean_url data[:url]}/artifact/#{artifact[:relativePath]}"
      file.common.downloads << dl
    end

    return BaseSanitizer.sanitize file
  end

  private
  def clean_url(url)
    if url[url.length - 1] == '/'
      url[url.length - 1] = ''
    end
    return url
  end
end
