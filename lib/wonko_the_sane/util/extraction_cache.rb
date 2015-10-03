class ExtractionCache
  def initialize(basedir)
    @basedir = basedir
    FileUtils.mkdir_p @basedir unless Dir.exist? @basedir
  end

  def get(archive, type, file)
    out = path(archive, type, file)
    FileUtils.mkdir_p File.dirname(out) unless Dir.exist? File.dirname(out)
    unless File.exist? out
      if type == :zip
        Zip::File.open archive do |arch|
          File.write out, arch.glob(file).first.get_input_stream.read
        end
      end
    end

    File.read out
  end

  def self.get(archive, type, file)
    @cache ||= ExtractionCache.new 'cache/extraction'
    @cache.get archive, type, file
  end

  private

  def path(archive, type, file)
    @basedir + '/' + File.basename(archive) + '/' + file
  end
end
