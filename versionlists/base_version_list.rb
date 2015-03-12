require_relative '../util/cache'

class BaseVersionList
  attr_accessor :artifact
  # @processed contains a list of version ids for all versions that have been processed. simply clear it to invalidate caches
  attr_accessor :processed
  attr_accessor :lastError

  def initialize(artifact)
    @artifact = artifact
    if File.exist? cache_file
      data = JSON.parse File.read(cache_file), symbolize_names: true
      @processed = data[:versions] ? data[:versions] : []
      @lastError = data[:lastError]
    else
      @processed = []
      @lastError = nil
    end
  end

  def refresh
    @lastError = nil
    begin
      versions = get_versions

      # check if some versions aren't in @processed (likely new ones) and fetch and process them
      versions.each do |version|
        next if not version
        id = version.is_a?(Array) ? version.first : version
        unless @processed.include? id
          files = get_version version
          next if files.nil? or (files.is_a? Array and files.empty?)

          files.each do |file|
            file.is_complete = true
            $registry.store file
          end if files and files.is_a? Array
          files.is_complete = true if files and files.is_a? Version
          $registry.store files if files and files.is_a? Version

          @processed << id
          write_cache_file
        end
      end

      FileUtils.touch cache_file
    rescue Exception => e
      binding.pry
      @lastError = e.message
    end
  end

  def invalidate(version = nil)
    if version
      @processed.remove version
    else
      @processed = []
    end
    write_cache_file
  end

  def last_modified
    if File.exist? cache_file
      File.mtime cache_file
    else
      nil
    end
  end

  def write_cache_file
    File.write cache_file, JSON.generate({
                                             versions: @processed,
                                             lastError: @lastError
                                         })
  end

  def cache_file
    'cache/' + @artifact + '.json'
  end

  def get_versions
    raise :AbstractMethodCallError
  end

  def get_version(id)
    raise :AbstractMethodCallError
  end

  def self.get_json(url)
    Yajl::Parser.parse HTTPCatcher.file(url, url), symbolize_names: true
  end
end
Dir.mkdir 'cache' unless Dir.exist? 'cache'
