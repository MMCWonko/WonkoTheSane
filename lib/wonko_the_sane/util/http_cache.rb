# :cookie_jar
# :timer, response.env[:duration]

require 'faraday'
require 'faraday_connection_pool'
require 'faraday/http_cache'
require 'faraday_middleware'
require 'faraday-cookie_jar'
require 'active_support/cache'
require 'uri'

class HTTPCache
  def initialize(basedir)
    @basedir = basedir
    FileUtils.mkdir_p @basedir unless Dir.exist? @basedir
    @mutex = Mutex.new
    @connections = {}
    @store = ActiveSupport::Cache.lookup_store(:file_store, @basedir + '/faraday_cache/')
  end

  # HTTP GETs a url if it doesn't exist locally
  def get(ctxt, url, key, check_stale = true)
    fetch ctxt, url, key, check_stale
  end

  def file(ctxt, url, key, check_stale = true)
    fetch ctxt, url, key, check_stale
    File.open @basedir + '/' + key, 'r'
  end

  private

  def fetch(ctxt, url, key, check_stale)
    cached_path = @basedir + '/' + key
    cached_dir = File.dirname cached_path
    FileUtils.mkdir_p cached_dir unless Dir.exist? cached_dir

    return if File.exists?(cached_path) && !check_stale

    TaskStack.in_background do
      uri = URI.parse url
      host = URI::HTTP.new(uri.scheme, uri.userinfo, uri.host, uri.port, nil, nil, nil, nil, nil).to_s

      connection = nil
      @mutex.synchronize do
        connection_id = host + ctxt.to_s
        @connections[connection_id] ||= create_faraday host, ctxt.to_s
        connection = @connections[connection_id]
      end
      Logging.logger[ctxt.to_s].debug "DL: #{url}"

      response = connection.get uri.path
      File.write cached_path, response.body
      response.body
    end
  end

  def create_faraday(host, ctxt)
    Faraday.new url: host do |faraday|
      faraday.use :cookie_jar
      faraday.response :raise_error
      faraday.response :chunked
      faraday.use :http_cache,
                  logger: Logging.logger[ctxt],
                  shared_cache: true,
                  serializer: Marshal,
                  store: @store
      faraday.response :follow_redirects
      faraday.request :retry, max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2,
                      exceptions: [Faraday::Error::ConnectionFailed]

      faraday.adapter :net_http_pooled
    end
  end

  public

  class << self; attr_accessor :cache; end
  self.cache = HTTPCache.new 'cache/network'

  def self.get(url, options = {})
    self.cache.get(options[:ctxt] || 'Download', url, (options.key?(:key) ? options[:key] : url), options[:check_stale] || false)
  end

  def self.file(url, options = {})
    self.cache.file(options[:ctxt] || 'Download', url, (options.key?(:key) ? options[:key] : url), options[:check_stale] || false)
  end
end
