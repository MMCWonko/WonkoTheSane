# http://www.ericson.net/content/2011/04/caching-http-requests-with-ruby/
# TODO proper etags and other caching stuff
class HTTPCache
  def initialize(basedir)
    @basedir = basedir
    FileUtils.mkdir_p @basedir unless Dir.exist? @basedir
    @etags = {}
    @etags = JSON.parse File.read(@basedir + '/etags.json') if File.exists? @basedir + '/etags.json'
  end

  # HTTP GETs a url if it doesn't exist locally
  def get(ctxt, url, key, check_stale = true)
    fetch ctxt, url, key, check_stale
    IO.read @basedir + '/' + key
  end

  def file(ctxt, url, key, check_stale = true)
    fetch ctxt, url, key, check_stale
    File.new @basedir + '/' + key, 'r'
  end

  private
  def fetch(ctxt, url, key, check_stale)
    cached_path = @basedir + '/' + key
    cached_dir = File.dirname cached_path
    FileUtils.mkdir_p cached_dir unless Dir.exist? cached_dir

    TaskStack.in_background do
      if should_check cached_path, check_stale
        Logging.logger[ctxt.to_s].debug "DL: #{url}"
        resp = http_get ctxt.to_s, url, cached_path
        unless resp == nil
          File.open(cached_path, 'w') do |f|
            f.write resp.body
          end
        end
      end
    end
  end

  # get a file, using the local cached file modified timestamp to make sture we don't re-download stuff pointlessly
  # this also *should* handle redirection properly
  def http_get(ctxt, url, cached_path, limit = 10, http = nil)
    # too many redirects...
    raise ArgumentError, 'too many HTTP redirects' if limit == 0

    uri = url.is_a?(URI) ? url : URI.parse(url)

    local_date = Time.parse("1985-10-28")
    local_date = File.mtime cached_path if File.exists? cached_path

    if http.nil?
      Net::HTTP.start uri.hostname, uri.port, :use_ssl => uri.scheme == 'https' do |http|
        return http_get_internal ctxt, uri, cached_path, limit, http, local_date
      end
    else
      return http_get_internal ctxt, uri, cached_path, limit, http, local_date
    end
  end
  def http_get_internal(ctxt, uri, cached_path, limit = 10, http = nil, local_date = nil)
    existing_etag = @etags[uri]

    # start by doing a HEAD request
    head_req = Net::HTTP::Head.new uri
    head_req.add_field 'If-None-Match', existing_etag if existing_etag
    head_req.add_field 'If-Modified-Since', local_date.httpdate
    head_resp = http.request head_req

    case head_resp
    when Net::HTTPSuccess
      # don't re-check this
      checked cached_path

      remote_date = head_resp['Last-Modified'] ? Time.httpdate(head_resp['Last-Modified']) : Time.now
      new_etag = head_resp['ETag']

      # if the remote resource has been modified later than the local file, grab it and return it
      if remote_date > local_date || existing_etag != new_etag || !file_valid?(head_resp, cached_path)
        req = Net::HTTP::Get.new(uri)
        resp = http.request Net::HTTP::Get.new(uri)
        Logging.logger[ctxt].debug 'GOT FULL FILE'

        @etags[uri] = new_etag if new_etag
        File.write @basedir + '/etags.json', JSON.pretty_generate(@etags)

        return resp
      else
        Logging.logger[ctxt].debug 'CACHE HIT'
        return nil
      end
    when Net::HTTPRedirection
      if head_resp.code == "304"
        Logging.logger[ctxt].debug 'CACHE HIT'
        checked cached_path
        return nil
      end

      location = head_resp['Location']
      Logging.logger[ctxt].debug "Redirected to #{location} - code #{head_resp.code}"
      newurl = URI.parse location
      newurl = URI.join uri.to_s, location if newurl.relative?
      return http_get ctxt, newurl, cached_path, limit - 1, http
    else
      Logging.logger[ctxt].warn "#{location} failed: #{head_resp.code}"
      checked cached_path
      return nil
    end
  end

  def file_valid?(response, path)
    if response['Content-Length']
      return false if response['Content-Length'].to_i != File.size(path)
    end
    if response['Content-MD5']
      return false if response['Content-MD5'] != FileHashCache.get_md5(path)
    end
    return true
  end

  @@checked_paths = Set.new
  def should_check(cached_path, check_stale)
    # if the file doesn't exist locally, or we should check for stale cache
    if !File.exist? cached_path or check_stale
      # but only once per run
      return !@@checked_paths.include?(cached_path)
    end
    # otherwise don't check
    return false
  end

  def checked(cached_path)
    @@checked_paths.add cached_path
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
