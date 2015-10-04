module WonkoTheSane
  module Util
    class VersionParser
      private

      class << self; attr_accessor :cache; end
      self.cache = {}

      def self.parse(string)
        return self.cache[string] if self.cache.has_key? string
        appendix = string.scan(/\-.*$/).first
        sections = string.sub(/\-.*$/, '').split '.'
        sections.map! do |sec|
          test = Integer sec rescue nil
          test || sec
        end

        result = {
          appendix: appendix,
          sections: sections
        }
        self.cache[string] = result
        return result
      end

      def self.appendix_values(appendix)
        str = appendix.scan /[a-zA-Z]*/
        digits = appendix.scan(/\d*/).join.to_i
        ret = case str.find { |s| !s.blank? }
              when 'a'
                [0, digits]
              when 'alpha'
                [0, digits]
              when 'b'
                [1, digits]
              when 'beta'
                [1, digits]
              when 'rc'
                [2, digits]
              when 'pre'
                [2, digits]
              end
        ret || [-1, digits]
      end

      def self.compare_values(first, second)
        if first < second
          -1
        elsif first > second
          1
        else
          0
        end
      end

      public
      def self.compare(string1, string2)
        par1 = VersionParser.parse string1
        par2 = VersionParser.parse string2
        size = [par1[:sections].length, par2[:sections].length].max
        ret = 0
        size.times do |index|
          val1 = par1[:sections].length > index ? par1[:sections][index] : 0
          val2 = par2[:sections].length > index ? par2[:sections][index] : 0
          ret = VersionParser.compare_values val1.to_i, val2.to_i
          break unless ret == 0
        end
        if ret == 0
          if par1[:appendix] && par2[:appendix]
            appendix1 = VersionParser.appendix_values par1[:appendix]
            appendix2 = VersionParser.appendix_values par2[:appendix]
            ret = VersionParser.compare_values appendix1[0], appendix2[0]
            if ret == 0
              ret = VersionParser.compare_values appendix1[1], appendix2[1]
            end
          elsif par1[:appendix]
            ret = -1
          elsif par2[:appendix]
            ret = 1
          end
        end
        return ret
      end

      def self.less?(string1, string2)
        VersionParser.compare(string1, string2) == -1
      end
      def self.greater?(string1, string2)
        VersionParser.compare(string1, string2) == 1
      end
      def self.equal?(string1, string2)
        VersionParser.compare(string1, string2) == 0
      end
      def self.less_or_equal?(string1, string2)
        ret = VersionParser.compare string1, string2
        ret == 0 or ret == -1
      end
      def self.greater_or_equal?(string1, string2)
        ret = VersionParser.compare string1, string2
        ret == 0 or ret == 1
      end
      def self.not_equal?(string1, string2)
        VersionParser.compare(string1, string2) != 0
      end
    end
  end
end
