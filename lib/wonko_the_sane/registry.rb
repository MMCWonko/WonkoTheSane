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
    return {index: []} unless File.exists? 'files/index.json'
    $rw.read_index JSON.parse File.read 'files/index.json'
  end

  def store(version)
    if version.is_a? Array
      version.each do |f|
        store(f)
      end
    else
      BaseSanitizer.sanitize(version, DownloadsFixer).each do |ver|
        begin
          Dir.mkdir 'files/' + ver.uid unless Dir.exist? 'files/' + ver.uid
          File.write ver.local_filename + '.new', JSON.pretty_generate($rw.write_version ver)
          File.write ver.local_filename, JSON.pretty_generate($old_format.write_version ver)
          WonkoTheSane.wonkoweb_uploader.version_changed ver.uid, ver.version

          vindex = version_index ver.uid
          vindex.add_version ver
          store_version_index vindex

          ind = index
          next if ind[:index].find { |i| ver.uid == i[:uid] } # early exit if the uid already exists in the index
          ind[:formatVersion] = 0
          ind[:index] << {uid: ver.uid}
          File.write 'files/index.json', JSON.pretty_generate($rw.write_index ind)
        rescue Exception => e
          Logging.logger[ver.uid].error 'Unable to store: ' + ver.version
          raise e
        end
      end
    end
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
    @instance ||= Registry.new
  end
end
