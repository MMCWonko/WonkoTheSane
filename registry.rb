class Registry
  def index(uid)
    if File.exist? VersionIndex.local_filename(uid)
      $rw.read_index File.read(VersionIndex.local_filename uid)
    else
      VersionIndex.new uid
    end
  end

  def store(version)
    if version.is_a? Array
      version.each do |f| store(f) end
    else
      Dir.mkdir 'files/' + version.uid unless Dir.exist? 'files/' + version.uid
      File.write version.local_filename, $rw.write_version(version)

      index = index version.uid
      index.add_version version
      File.write VersionIndex.local_filename(index.uid), $rw.write_index(index)
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