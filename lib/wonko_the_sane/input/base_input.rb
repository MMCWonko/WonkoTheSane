class BaseInput
  def logger
    Logging.logger[@artifact]
  end
end

class BaseSanitizer
  def self.sanitize(file)
    raise :AbstractMethodCallError
  end

  def self.sanitize(input, *sanitizers)
    output = [input]
    sanitizers.each do |sanitizer|
      tmp = []
      output.each do |file|
        result = sanitizer.sanitize(file.clone)
        if result.is_a? Array
          tmp = tmp + result
        elsif not result.nil?
          tmp << result
        end
      end
      output = tmp
    end
    output
  end
end

class DownloadsFixer < BaseSanitizer
  def self.sanitize(file)
    file.client.downloads.map! do |download|
      if !download.size || download.sha256.blank?
        info = WonkoTheSane::Util::DeepStorageCache.get_info download.usable_url, ctxt: file.uid
        download.size = info[:size]
        download.sha256 = info[:sha256]
      end
      download
    end
    file.server.downloads.map! do |download|
      if !download.size || download.sha256.blank?
        info = WonkoTheSane::Util::DeepStorageCache.get_info download.usable_url, ctxt: file.uid
        download.size = info[:size]
        download.sha256 = info[:sha256]
      end
      download
    end
    file
  end
end
