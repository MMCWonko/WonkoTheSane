class BaseInput
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
        #puts "Running #{sanitizer.to_s} on #{file.id}"
        result = sanitizer.sanitize(file.clone)
        if result.is_a? Array
          tmp = tmp + result
        elsif not result.nil?
          tmp << result
        end
      end
      output = tmp
    end
    return output
  end
end