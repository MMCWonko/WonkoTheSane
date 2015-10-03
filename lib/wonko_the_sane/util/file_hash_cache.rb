class FileHashCache
  def initialize(file, algorithm)
    @file = file
    @algorithm = algorithm
    @data = JSON.parse File.read(@file), symbolize_names: true if File.exists? @file
    @data ||= {}
  end

  def get(file)
    name = (file.is_a?(File) ? file.path : file).to_sym
    timestamp = (file.is_a?(File) ? file.mtime : File.mtime(file)).to_i
    size = file.is_a?(File) ? file.size : File.size(file)
    if !@data[name] || !@data[name][:timestamp] == timestamp || !@data[name][:size] == size
      hash = digest(file.is_a?(File) ? file.read : File.read(file))
      @data[name] = {
          timestamp: timestamp,
          size: size,
          hash: hash
      }
      File.write @file, JSON.pretty_generate(@data)
    end
    @data[name][:hash]
  end

  def digest(data)
    if @algorithm == :sha256
      Digest::SHA256.hexdigest data
    elsif @algorithm == :md5
      Digest::MD5.hexdigest data
    end
  end

  def self.get(file)
    @sha256_cache ||= FileHashCache.new 'cache/filehashes.json', :sha256
    @sha256_cache.get file
  end

  def self.get_md5(file)
    @md5_cache ||= FileHashCache.new 'cache/filehashes.md5.json', :md5
    @md5_cache.get file
  end
end
