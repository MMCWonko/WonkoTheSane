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

    # "artifacts": [
    #    {
    #        "displayPath": "industrialcraft-2-2.2.676-experimental.jar",
    #        "fileName": "industrialcraft-2-2.2.676-experimental.jar",
    #        "relativePath": "build/libs/industrialcraft-2-2.2.676-experimental.jar"
    #    }
    #]
    # data[:url] /artifact/ artifacts[n][:relativePath]

    return BaseSanitizer.sanitize file
  end
end
