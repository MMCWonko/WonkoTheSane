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
    cached_path = @basedir + '/' + key
    cached_dir = File.dirname cached_path
    FileUtils.mkdir_p cached_dir unless Dir.exist? cached_dir
    if File.exists?(cached_path)
      puts "Getting file #{key} from cache"
      return IO.read(cached_path)
    else
      puts "Getting file #{key} from URL #{url}"
      resp = Net::HTTP.get_response(URI.parse(url))
      data = resp.body

      File.open(cached_path, 'w') do |f|
        f.puts data
      end

      return data
    end
  end

  @@defaultCatcher = HTTPCatcher.new 'cache/network'
  def self.get(url, key)
    @@defaultCatcher.get url, key
  end
end