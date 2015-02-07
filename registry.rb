class Registry
  def version_index(uid)
    if File.exist? VersionIndex.local_filename(uid)
      $rw.read_version_index File.read(VersionIndex.local_filename uid)
    else
      VersionIndex.new uid
    end
  end

  def index
    if File.exists? 'files/index.json'
      $rw.read_index File.read('files/index.json')
    else
      {
          index: []
      }
    end
  end

  def store(version)
    if version.is_a? Array
      version.each do |f| store(f) end
    else
      Dir.mkdir 'files/' + version.uid unless Dir.exist? 'files/' + version.uid
      File.write version.local_filename, $rw.write_version(version)

      vindex = version_index version.uid
      vindex.add_version version
      File.write VersionIndex.local_filename(vindex.uid), $rw.write_version_index(vindex)

      ind = index
      ind[:index].each do |i|
        if version.uid == i[:uid]
          return
        end
      end
      ind[:index] << {
          uid: version.uid
      }
      File.write 'files/index.json', $rw.write_index(ind)
    end
  end
  def retrieve(id, version)
    if File.exist? Version.local_filename(id, version)
      return $rw.read_version File.read(Version.local_filename id, version)
    else
      return nil
    end
  end
end
Dir.mkdir 'files' unless Dir.exist? 'files'
$registry = Registry.new