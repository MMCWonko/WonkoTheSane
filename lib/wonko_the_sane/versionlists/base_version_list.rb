class BaseVersionList
  attr_accessor :artifact
  # @processed contains a list of version ids for all versions that have been processed. simply clear it to invalidate caches
  attr_accessor :processed
  attr_accessor :last_error

  def initialize(artifact)
    @artifact = artifact
    if File.exist? cache_file
      data = JSON.parse File.read(cache_file), symbolize_names: true
      @processed = data[:versions] || []
      @last_error = data[:last_error]
    else
      @processed = []
    end
  end

  def refresh
    @last_error = nil
    versions = get_versions

    # check if some versions aren't in @processed (likely new ones) and fetch and process them
    versions.each do |version|
      next if version.nil?
      begin
        id = version.is_a?(Array) ? version.first : version
        unless @processed.include? id
          files = get_version version
          next if files.nil? || (files.is_a?(Array) && files.empty?)

          if files.is_a?(Array)
            files.flatten.each do |file|
              file.is_complete = true
              Registry.instance.store file
            end
          else
            files.is_complete = true
            Registry.instance.store files
          end

          @processed << id
          write_cache_file
        end
      rescue => e
        logger.error e.message
        logger.warn e.backtrace.first
        binding.pry if $stdout.isatty && ENV['DEBUG_ON_ERROR']
        @last_error = e.message
      end
    end

    FileUtils.touch cache_file
  rescue => e
    logger.error e.message
    logger.warn e.backtrace.first
    binding.pry if $stdout.isatty && ENV['DEBUG_ON_ERROR']
    @last_error = e.message
  end

  def logger
    Logging.logger[@artifact]
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
    File.write cache_file, JSON.pretty_generate({
                                                    versions: @processed,
                                                    lastError: @last_error
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

  def get_json(url)
    Yajl::Parser.parse HTTPCache.file(url, ctxt: @artifact, check_stale: true), symbolize_keys: true
  end

  def get_json_cached(url)
    Yajl::Parser.parse HTTPCache.file(url, ctxt: @artifact, check_stale: false), symbolize_keys: true
  end
end
Dir.mkdir 'cache' unless Dir.exist? 'cache'
