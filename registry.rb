class Registry
  def versions(id)
    if File.exist? 'files/' + id + '.versions.json'
      JSON.parse File.read('files/' + id + '.versions.json')
    else
      []
    end
  end

  def store(file)
    if file.is_a? Array
      file.each do |f| store(f) end
    else
      Dir.mkdir 'files/' + file.id unless Dir.exist? 'files/' + file.id
      File.write filename(file.id, file.version), file.to_json

      vers = versions file.id
      ver = {
          id: file.version,
          type: file.type
      }
      ver[:name] = file.versionName if file.versionName and file.versionName != ''
      vers << ver
      File.write 'files/' + file.id + '.versions.json', JSON.generate(vers.uniq)
    end
  end
  def retrieve(id, version)
    if File.exist? filename(id, version)
      return VersionFile.from_json File.read(filename id, version)
    else
      return nil
    end
  end

  def filename(id, version)
    return 'files/' + id + '/' + version + '.json'
  end
end
Dir.mkdir 'files' unless Dir.exist? 'files'
$registry = Registry.new