class ForgeFilesModsInput < BaseInput
  def initialize(artifact)
    @artifact = artifact
  end

  def parse(data, version)
    file = Version.new

    file.uid = @artifact
    file.version = version
    file.time = data[:info]

    f = data[:files].first
    file.requires << Referenced.new('net.minecraft', f[:mcver])

    # TODO: f[:url]

    return BaseSanitizer.sanitize file
  end
end
