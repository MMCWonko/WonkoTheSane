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
    @etags = {}
    @etags = JSON.parse File.read(@basedir + '/etags.json') if File.exists? @basedir + '/etags.json'
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

    unless check_stale
      return if File.exists? cached_path
    end

    TaskStack.in_background do
      uri = URI.parse url
      host = URI::HTTP.new(uri.scheme, uri.userinfo, uri.host, uri.port, nil, nil, nil, nil, nil).to_s

      connection = nil
      @mutex.synchronize do
        connection_id = host + ctxt.to_s
        unless @connections.key? connection_id
          @connections[connection_id] = Faraday.new url: host do |faraday|
            faraday.use :cookie_jar
            faraday.response :raise_error
            faraday.response :chunked
            faraday.use :http_cache,
                        logger: Logging.logger[ctxt.to_s],
                        shared_cache: true,
                        serializer: Marshal,
                        store: @store
            faraday.response :follow_redirects
            faraday.request :retry, max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2,
                        exceptions: [Faraday::Error::ConnectionFailed]

            faraday.adapter :net_http_pooled
          end
        end
        connection = @connections[connection_id]
      end
      Logging.logger[ctxt.to_s].debug "DL: #{url}"

      response = connection.get uri.path
      File.write cached_path, response.body
      response.body
    end
  end

  public
  @@defaultCatcher = HTTPCache.new 'cache/network'
  def self.get(url, options = {})
    @@defaultCatcher.get(options[:ctxt] || 'Download', url, (options.key?(:key) ? options[:key] : url), options[:check_stale] || false)
  end
  def self.file(url, options = {})
    @@defaultCatcher.file(options[:ctxt] || 'Download', url, (options.key?(:key) ? options[:key] : url), options[:check_stale] || false)
  end
end
