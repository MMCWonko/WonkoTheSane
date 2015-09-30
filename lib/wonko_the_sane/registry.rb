class Registry
  def version_index(uid)
    return VersionIndex.new uid unless File.exists? VersionIndex.local_filename uid
    $rw.read_version_index JSON.parse File.read(VersionIndex.local_filename uid)
  end

  def store_version_index(index)
    File.write index.local_filename, JSON.pretty_generate($rw.write_version_index index)
    WonkoTheSane.wonkoweb_uploader.file_changed index.uid
  end

  def index
    return { index: [] } unless File.exists? 'files/index.json'
    $rw.read_index JSON.parse File.read 'files/index.json'
  end

  def store(version)
    if version.is_a? Array
      version.each do |f| store(f) end
    else
      BaseSanitizer.sanitize(version, DownloadsFixer).each do |version|
        Dir.mkdir 'files/' + version.uid unless Dir.exist? 'files/' + version.uid
        File.write version.local_filename + '.new', JSON.pretty_generate($rw.write_version version)
        File.write version.local_filename, JSON.pretty_generate($old_format.write_version version)
        WonkoTheSane.wonkoweb_uploader.version_changed version.uid, version.version

        vindex = version_index version.uid
        vindex.add_version version
        store_version_index vindex

        ind = index
        next if ind[:index].find { |i| version.uid == i[:uid] } # early exit if the uid already exists in the index
        ind[:formatVersion] = 0
        ind[:index] << { uid: version.uid }
        File.write 'files/index.json', JSON.pretty_generate($rw.write_index ind)
      end
    end
  rescue Exception => e
    Logging.logger[version.uid].error 'Unable to store: ' + version.version
    raise e
  end

  def retrieve(id, version)
    if File.exist? WonkoVersion.local_filename(id, version)
      $rw.read_version JSON.parse File.read(WonkoVersion.local_filename(id, version) + '.new')
    else
      nil
    end
  end

  def self.instance
    Dir.mkdir 'files' unless Dir.exist? 'files'
    @@instance ||= Registry.new
  end
end
