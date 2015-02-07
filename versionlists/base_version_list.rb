require_relative '../util/cache'

class BaseVersionList
  attr_accessor :artifact
  # @processed contains a list of version ids for all versions that have been processed. simply clear it to invalidate caches
  attr_accessor :processed

  def initialize(artifact)
    @artifact = artifact
    if File.exist? 'cache/' + @artifact + '.json'
      @processed = JSON.parse File.read('cache/' + @artifact + '.json')
    else
      @processed = []
    end
  end

  def refresh
    versions = get_versions

    # check if some versions aren't in @processed (likely new ones) and fetch and process them
    versions.each do |version|
      id = version.is_a?(Array) ? version.first : version
      unless @processed.include? id
        files = get_version version
        next if files.nil? or (files.is_a? Array and files.empty?)

        files.each do |file|
          $registry.store file
        end if files and files.is_a? Array
        $registry.store files if files and files.is_a? Version

        @processed << id
        File.write 'cache/' + @artifact + '.json', JSON.generate(@processed)
      end
    end
  end

  def get_versions
    raise :AbstractMethodCallError
  end

  def get_version(id)
    raise :AbstractMethodCallError
  end

  def self.get_json(url)
    JSON.parse HTTPCatcher.get(url, url), symbolize_names: true
  end
end
Dir.mkdir 'cache' unless Dir.exist? 'cache'