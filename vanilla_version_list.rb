require_relative 'base_version_list'

class VanillaVersionList < BaseVersionList
  def initialize
    super('net.minecraft')
    @input = MojangInput.new('net.minecraft')
  end

  def get_versions
    result = BaseVersionList.get_json 'http://s3.amazonaws.com/Minecraft.Download/versions/versions.json'

    return result[:versions].map do |obj| obj[:id] end
  end

  def get_version(id)
    @input.parse BaseVersionList.get_json('http://s3.amazonaws.com/Minecraft.Download/versions/' + id + '/' + id + '.json')
  end
end