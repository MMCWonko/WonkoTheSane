require 'fileutils'
require 'rubygems'
require 'zip'
require 'set'

# http://www.ericson.net/content/2011/04/caching-http-requests-with-ruby/
# TODO proper etags and other caching stuff
class HTTPCatcher
  def initialize(basedir)
    @basedir = basedir
    FileUtils.mkdir_p @basedir unless Dir.exist? @basedir
    @etags = {}
    @etags = JSON.parse File.read(@basedir + '/etags.json') if File.exists? @basedir + '/etags.json'
  end

  # HTTP GETs a url if it doesn't exist locally
  def get(url, key, check_stale = true)
    fetch url, key, check_stale
    IO.read @basedir + '/' + key
  end

  def file(url, key, check_stale = true)
    fetch url, key, check_stale
    File.new @basedir + '/' + key, 'r'
  end

  private
  def fetch(url, key, check_stale)
    cached_path = @basedir + '/' + key
    cached_dir = File.dirname cached_path
    FileUtils.mkdir_p cached_dir unless Dir.exist? cached_dir

    if should_check cached_path, check_stale
      puts "DL: #{url}"
      resp = http_get url, cached_path
      if resp == nil
        return
      end
      File.open(cached_path, 'w') do |f|
        f.puts resp.body
      end
    end
  end

  # get a file, using the local cached file modified timestamp to make sture we don't re-download stuff pointlessly
  # this also *should* handle redirection properly
  def http_get(url, cached_path, limit = 10, http = nil)
    # too many redirects...
    raise ArgumentError, 'too many HTTP redirects' if limit == 0

    uri = URI.parse(url)

    local_date = Time.parse("1985-10-28")
    local_date = File.mtime cached_path if File.exists? cached_path

    if http.nil?
      Net::HTTP.start uri.hostname, uri.port, :use_ssl => uri.scheme == 'https' do |http|
        return http_get_internal uri, cached_path, limit, http, local_date
      end
    else
      return http_get_internal uri, cached_path, limit, http, local_date
    end
  end
  def http_get_internal(uri, cached_path, limit = 10, http = nil, local_date = nil)
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

      remote_date = Time.httpdate(head_resp['Last-Modified'])
      new_etag = head_resp['ETag']

      # if the remote resource has been modified later than the local file, grab it and return it
      puts "Comparing #{local_date.httpdate} to #{remote_date.httpdate}"
      if remote_date > local_date && existing_etag != new_etag
        req = Net::HTTP::Get.new(uri)
        resp = http.request Net::HTTP::Get.new(uri)
        puts "GOT FULL FILE"

        @etags[uri] = new_etag if new_etag
        File.write @basedir + '/etags.json', JSON.generate(@etags)

        return resp
      else
        puts "CACHE HIT"
        return nil
      end
    when Net::HTTPRedirection
      if head_resp.code == "304"
        puts "CACHE HIT"
        checked cached_path
        return nil
      end

      location = head_resp['Location']
      puts "Redirected to #{location} - code #{head_resp.code}"
      newurl = URI.parse location
      newurl = URI.join uri.to_s, location if newurl.relative?
      return http_get newurl, cached_path, limit - 1, http
    else
      puts "Failed: #{head_resp.code}"
      checked cached_path
      return nil
    end
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
  @@defaultCatcher = HTTPCatcher.new 'cache/network'
  def self.get(url, key=nil, check_stale = true)
    @@defaultCatcher.get(url, (key ? key : url), check_stale)
  end
  def self.file(url, key=nil, check_stale = true)
    @@defaultCatcher.file(url, (key ? key : url), check_stale)
  end
end

class ExtractionCache
  def initialize(basedir)
    @basedir = basedir
    FileUtils.mkdir_p @basedir unless Dir.exist? @basedir
  end

  def get(archive, type, file)
    out = path(archive, type, file)
    FileUtils.mkdir_p File.dirname(out) unless Dir.exist? File.dirname(out)
    if not File.exist? out
      if type == :zip
        Zip::File.open archive do |arch|
          File.write out, arch.glob(file).first.get_input_stream.read
        end
      end
    end

    return File.read out
  end

  @@defaultCache = ExtractionCache.new 'cache/extraction'
  def self.get(archive, type, file)
    @@defaultCache.get archive, type, file
  end

  private
  def path(archive, type, file)
    @basedir + '/' + File.basename(archive) + '/' + file
  end
end

class FileHashCache
  def initialize(file)
    @file = file
    @data = {}
    if File.exists? @file
      @data = JSON.parse File.read(@file), symbolize_names: true
    end
  end

  def get(file)
    name = (file.is_a?(File) ? file.path : file).to_sym
    timestamp = (file.is_a?(File) ? file.mtime : File.mtime(file)).to_i
    size = file.is_a?(File) ? file.size : File.size(file)
    if not @data[name] or not @data[name][:timestamp] == timestamp or not @data[name][:size] == size
      hash = Digest::SHA256.hexdigest(file.is_a?(File) ? file.read : File.read(file))
      @data[name] = {
        timestamp: timestamp,
        size: size,
        hash: hash
      }
      File.write @file, JSON.pretty_generate(@data)
    end
    return @data[name][:hash]
  end

  @@defaultCache = FileHashCache.new 'cache/filehashes'
  def self.get(file)
    @@defaultCache.get file
  end
end
