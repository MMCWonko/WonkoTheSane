require 'fileutils'

class Registry
  def version_index(version)
    return VersionIndex.new version.uid, version.name unless File.exists? VersionIndex.local_filename version.uid
    $rw.read_version_index JSON.parse File.read(VersionIndex.local_filename version.uid)
  end

  def store_version_index(index)
    File.write index.local_filename, JSON.pretty_generate($rw.write_version_index index)
    FileUtils.copy index.local_filename, "#{Registry.out_dir}/#{index.uid}.json" unless Registry.out_dir.blank?
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
          unless Registry.out_dir.blank?
            FileUtils.copy ver.local_filename + '.new', "#{Registry.out_dir}/#{ver.uid}-#{ver.version}.new.json"
            FileUtils.copy ver.local_filename, "#{Registry.out_dir}/#{ver.uid}-#{ver.version}.json"
          end

          vindex = version_index ver
          vindex.add_version ver
          store_version_index vindex

          ind = index
          next if ind[:index].find { |i| ver.uid == i[:uid] } # early exit if the uid already exists in the index
          ind[:formatVersion] = 1
          ind[:index] << {
            uid: ver.uid,
            name: ver.name
          }
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
    FileUtils.mkdir_p 'files' unless Dir.exist? 'files'
    FileUtils.mkdir_p out_dir unless out_dir.blank? || Dir.exists?(out_dir)
    @instance ||= Registry.new
  end

  def self.out_dir
    WonkoTheSane.configuration.out_dir
  end
end
