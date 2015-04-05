require 'fileutils'
require 'rubygems'
require 'zip'
require 'set'

# http://www.ericson.net/content/2011/04/caching-http-requests-with-ruby/
# TODO etags and other caching stuff
class HTTPCatcher
  def initialize(basedir)
    @basedir = basedir
    FileUtils.mkdir_p @basedir unless Dir.exist? @basedir
  end

  # HTTP GETs a url if it doesn't exist locally
  def get(url, key)
    fetch url, key
    IO.read @basedir + '/' + key
  end

  def file(url, key)
    fetch url, key
    File.new @basedir + '/' + key, 'r'
  end

  private
  def fetch(url, key)
    cached_path = @basedir + '/' + key
    cached_dir = File.dirname cached_path
    FileUtils.mkdir_p cached_dir unless Dir.exist? cached_dir

    if should_check(cached_path)
      puts "DL: #{url}"
      resp = http_get(url, cached_path)
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
  def http_get(url, cached_path, limit = 10)
    # too many redirects...
    raise ArgumentError, 'too many HTTP redirects' if limit == 0

    uri = URI.parse(url)
    head_req = Net::HTTP::Head.new(uri)

    localDate = Time.parse("1985-10-28")
    if File.exists?(cached_path)
      file = File.stat cached_path
      localDate = file.mtime
    end

    head_resp = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
      http.request(head_req)
    }

    case head_resp
    when Net::HTTPSuccess
      checked(cached_path)
      remoteDate = Time.httpdate(head_resp['Last-Modified'])
      # if the remote resource has been modified later than the local file, grab it and return it
      puts "Comparing #{localDate.httpdate} to #{remoteDate.httpdate}"
      if(remoteDate > localDate)
        req = Net::HTTP::Get.new(uri)
        resp = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
          http.request(req)
        }
        puts "GOT FULL FILE"
        return resp
      end
      puts "CACHE HIT"
      return nil # otherwise
    when Net::HTTPRedirection
      if head_resp.code == "304"
        puts "THIS SHOULDN'T BE!"
        checked(cached_path)
        return nil
      end
      location = head_resp['Location']
      puts "Redirected to #{location} - code #{head_resp.code}"
      newurl=URI.parse(head_resp.header['location'])
      if(newurl.relative?)
        newurl=URI.join(url, head_resp.header['location'])
      end
      return http_get(newurl, cached_path, limit - 1)
    else
      puts "Failed: #{head_resp.code}"
      checked(cached_path)
      return nil
    end
  end

  def should_check(cached_path)
    if $checked_paths == nil
      return true
    end
    return not( $checked_paths.include? cached_path)
  end

  def checked(cached_path)
    if $checked_paths == nil
      $checked_paths = Set.new
    end
    $checked_paths.add cached_path
  end

  public
  @@defaultCatcher = HTTPCatcher.new 'cache/network'
  def self.get(url, key=nil)
    @@defaultCatcher.get url, (key ? key : url)
  end
  def self.file(url, key=nil)
    @@defaultCatcher.file url, (key ? key : url)
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
