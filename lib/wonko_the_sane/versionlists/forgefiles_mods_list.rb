class ForgeFilesModsList < BaseVersionList
  def initialize(uid, name, url_id)
    super(uid, name)
    @url_id = url_id
    @input = ForgeFilesModsInput.new(uid, name)
  end

  def get_versions
    get_json("http://files.minecraftforge.net/#{@url_id}/json")[:builds].map do |build|
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
