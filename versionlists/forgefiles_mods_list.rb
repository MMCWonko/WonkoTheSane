require 'pry'

class ForgeFilesModsList < BaseVersionList
  def initialize(artifact, urlId)
    super(artifact)
    @urlId = urlId
    @input = ForgeFilesModsInput.new(artifact)
  end

  def get_versions
    result = BaseVersionList.get_json "http://files.minecraftforge.net/#{@urlId}/json"

    return result[:builds].map do |build|
      [
          build[:version],
          build
      ]
    end
  end

  def get_version(id)
    @input.parse id[1], id[0]
  end
end