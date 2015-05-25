module WonkoTheSane
  class WonkoWeb
    include HTTParty

    class UploadError < ResponseError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end
    end

    def initialize(benchmark)
      self.class.base_uri Settings[:wonkoweb][:host]
      self.class.headers 'X-Uploader-Name' => Settings[:wonkoweb][:name],
                         'X-Uploader-Token' => Settings[:wonkoweb][:token],
                         'X-WUR-Enabled' => 'true',
                         'Content-Type' => 'application/json'

      @benchmark = benchmark
    end

    def index
      self.class.get(path 'index').with_indifferent_access
    end

    def file(uid)
      self.class.get(path uid).with_indifferent_access
    end

    def version(uid, version)
      self.class.get(path uid, version).with_indifferent_access
    end

    def upload_file(data)
      return if data.nil?
      uid = data[:uid]
      theirs = @benchmark.benchmark('upload_file.theirs') { file uid rescue nil }

      data.delete :versions # only stubs here
      data[:name] ||= data[:uid]

      upload_hash path, path(uid), data, theirs, false
    end

    def upload_version(data)
      return if data.nil?
      uid = data[:uid]
      version = data[:version]
      theirs = @benchmark.benchmark('upload_version.theirs') { version uid, version rescue nil }
      upload_hash path(uid), path(uid, version), data, theirs, true
    end

    private

    def upload_hash(create_path, update_path, ours, theirs, allow_overwrite)
      caller = ours[:version] ? 'upload_version' : 'upload_file'
      res = if theirs.nil? || (theirs[:errors] && theirs[:errors].size > 0)
              # upload entire file
              @benchmark.benchmark(caller + '.create') { self.class.post create_path, body: JSON.generate(ours) }
            else
              # upload changes

              body = JSON.parse JSON.generate ours # round-trip to "normalize" things
              # keep_if modifies in-place (why isn't it named keep_if! ????????)
              body.keep_if { |k, v| !(theirs[k.to_sym] == v) }
              body.keep_if { |k, v| theirs[k.to_sym].nil? || theirs[k.to_sym].to_s.empty? } unless allow_overwrite
              @benchmark.benchmark(caller + '.update') { self.class.patch update_path, body: JSON.generate(body) } unless body.empty?
            end

      if !res.nil? && (res.code >= 300 || JSON.parse(res.body).key?('errors'))
        binding.pry
        fail UploadError.new res.body[:errors]
      end
    end

    def path(*args)
      return '/api/v1.json' if args.nil? || args.empty?
      '/api/v1/' + args.map(&:to_s).join('/') + '.json'
    end
  end

  class WonkoWebUploader
    def initialize
      data = JSON.parse File.read 'uploader_queue.json' if File.exists? 'uploader_queue.json'
      data ||= {}
      data = data.with_indifferent_access
      @changed_files = data[:files] || []
      @changed_versions = data[:versions] || {}

      @benchmark = WonkoTheSane::Util::Benchmark.new
      @client = WonkoWeb.new @benchmark
    end

    def file_changed(uid)
      @changed_files << uid
      save_changes!
    end

    def version_changed(uid, version)
      @changed_versions[uid] ||= []
      @changed_versions[uid] << version
      save_changes!
    end

    def upload_changes!
      @changed_files.uniq!
      return if Settings[:wonkoweb][:host].nil?

      existing_uids = @benchmark.benchmark('initial index') { @client.index }[:index].map { |obj| obj[:uid] }
      logger.info "Uploading #{@changed_files.size} changed files to WonkoWeb at #{Settings[:wonkoweb][:host]}..."
      @changed_files.dup.each do |uid|
        begin
          @client.upload_file $rw.write_version_index Registry.instance.version_index uid
          existing_uids << uid
          @changed_files.delete uid
        rescue => e
          logger.error "Unable to upload file for #{uid} to WonkoWeb: #{e.message}"
          logger.warn e.backtrace.first
          binding.pry if $stdout.isatty && ENV['DEBUG_ON_ERROR']
        end
      end
      logger.info 'Done.'
      @benchmark.print_times true

      num_versions = @changed_versions.collect { |k, v| v.size }.inject :+
      logger.info "Uploading #{num_versions} changed versions to WonkoWeb at #{Settings[:wonkoweb][:host]}..."
      @changed_versions.dup.each do |uid, versions|
        versions.dup.each do |version|
          begin
            @client.upload_file $rw.write_version_index Registry.instance.version_index uid unless existing_uids.include? uid
            @client.upload_version $rw.write_version Registry.instance.retrieve uid, version
            versions.delete version
          rescue => e
            logger.error "Unable to upload version #{version} of #{uid} to WonkoWeb: #{e.message}"
            logger.warn e.backtrace.first
            binding.pry if $stdout.isatty && ENV['DEBUG_ON_ERROR']
          end
          @changed_versions.delete uid if versions.empty?
        end
      end
      logger.info 'Done.'
      @benchmark.print_times true

      save_changes!
    end

    private

    def logger
      Logging.logger[self]
    end

    def save_changes!
      data = {
          files: @changed_files,
          versions: @changed_versions
      }
      File.write 'uploader_queue.json', JSON.pretty_generate(data)
    end
  end
end
