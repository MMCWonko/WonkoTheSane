require_relative 'base_version_list'
require 'date'

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
    files = @input.parse BaseVersionList.get_json('http://s3.amazonaws.com/Minecraft.Download/versions/' + id + '/' + id + '.json')
    mcfile = files.find do |file|
      file.uid == 'net.minecraft'
    end
    if mcfile and mcfile.time > DateTime.iso8601('2013-06-25T15:08:56+02:00').to_time.to_i
      files
    else
      []
    end
  end
end