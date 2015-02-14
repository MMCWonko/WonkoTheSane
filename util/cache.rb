require 'fileutils'

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
    if File.exists?(cached_path)
      puts "Getting file #{key} from cache"
    else
      puts "Getting file #{key} from URL #{url}"
      resp = Net::HTTP.get_response(URI.parse(url))
      File.open(cached_path, 'w') do |f|
        f.puts resp.body
      end
    end
  end

  public
  @@defaultCatcher = HTTPCatcher.new 'cache/network'
  def self.get(url, key)
    @@defaultCatcher.get url, key
  end
  def self.file(url, key)
    @@defaultCatcher.file url, key
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