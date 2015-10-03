class JenkinsInput < BaseInput
  def initialize(artifact, file_regex)
    @artifact = artifact
    @file_regex = file_regex
  end

  def parse(data)
    return nil if data[:result] != 'SUCCESS'

    file = WonkoVersion.new
    file.uid = @artifact
    file.version = data[:number].to_s
    file.time = data[:timestamp]

    artifact = data[:artifacts].find do |art|
      path = art[:fileName]
      if @file_regex
        path.match @file_regex
      else
        %w(-api. -deobf. -dev. -javadoc. -library. -sources. -src. -util.).find { |infix| path.include? infix }.nil?
      end
    end

    if artifact.nil?
      logger.warn 'No valid artifact found for ' + file.version
    else
      dl = FileDownload.new
      dl.destination = "mods/#{file.uid}-#{file.version}.jar"
      dl.url = "#{clean_url data[:url]}/artifact/#{artifact[:relativePath]}"
      file.common.downloads << dl
    end

    BaseSanitizer.sanitize file
  end

  private

  def clean_url(url)
    url[url.length - 1] = '' if url[url.length - 1] == '/'
    url
  end
end
