require 'aws-sdk-resources'
require 'wonko_the_sane/util/http_cache'

module WonkoTheSane
  module Util
    class DeepStorageCache
      def initialize
        @resource = Aws::S3::Resource.new region: 'eu-west-1',
                                          credentials: Aws::Credentials.new(Settings[:aws][:client_id],
                                                                            Settings[:aws][:client_secret])
        @bucket = @resource.bucket 'wonkoweb-02jandal-xyz'

        @manifest = @bucket.object 'manifest.json'
        @entries = @manifest.exists? ? JSON.parse(@manifest.get.body.read, symbolize_keys: true) : {}
      end

      def get_info(url, options = {})
        return @entries[url] if @entries.key? url

        ctxt = options[:ctxt] || 'DeepStorageCache'

        file = HTTPCache.file url, check_stale: false, ctxt: options[:ctxt]
        info = self.class.info_for_file file, url

        @entries[url] = info
        @manifest.put body: JSON.pretty_generate(@entries)

        object = @bucket.object info[:file]
        unless object.exists? && object.size == info[:size]
          TaskStack.in_background do
            # convert the hex-encoded md5 to a base64-encoded md5, which is what S3 expects
            # http://anthonylewis.com/2011/02/09/to-hex-and-back-with-ruby/
            md5 = [info[:md5].scan(/../).map { |x| x.hex.chr }.join].pack 'm0'

            content_type = case url
                           when /\.zip$/, /\.jar$/
                             'application/zip'
                           else
                             ''
                           end

            Logging.logger[ctxt].debug "Uploading backup of #{url} to S3..."
            object.put body: file,
                       content_md5: md5,
                       content_type: content_type,
                       metadata: Hash[info.map { |k,v| [k.to_s, v.to_s]}]
            Logging.logger[ctxt].debug 'Backup successfully uploaded to S3'
          end
        end

        info
      end

      def self.get_info(url, options = {})
        if Settings[:aws][:client_id]
          @@instance ||= DeepStorageCache.new
          @@instance.get_info url, options
        else
          info_for_file HTTPCache.file(url, check_stale: false, ctxt: options[:ctxt]), url
        end
      end

      private

      def self.info_for_file(file, url)
        {
            url: url,
            file: url.gsub(/[&:$@=+,?\\^`><\{\}\[\]#%'"~|]/, '_'),
            size: file.size,
            md5: FileHashCache.get_md5(file),
            sha256: FileHashCache.get(file)
        }
      end
    end
  end
end
