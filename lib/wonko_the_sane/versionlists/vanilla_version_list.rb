require_relative 'base_version_list'
require 'date'

class VanillaVersionList < BaseVersionList
  def initialize
    super 'net.minecraft', 'Minecraft'
    @input = MojangInput.new 'net.minecraft', 'Minecraft'
  end

  def get_versions
    result = get_json 'http://s3.amazonaws.com/Minecraft.Download/versions/versions.json'
    @latest_release = result[:latest][:release]
    @latest_snapshot = result[:latest][:snapshot]

    result[:versions].map { |obj| obj[:id] }
  end

  def get_version(id)
    url = 'http://s3.amazonaws.com/Minecraft.Download/versions/' + id + '/' + id + '.json'
    json = if @latest_release == id || @latest_snapshot == id
             get_json url
           else
             get_json_cached url
           end
    files = @input.parse json
    mcfile = files.find { |file| file.uid == 'net.minecraft' }
    if mcfile && mcfile.time > DateTime.iso8601('2013-06-25T15:08:56+02:00').to_time.to_i
      files
    else
      []
    end
  end
end
