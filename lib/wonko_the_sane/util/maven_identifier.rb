module WonkoTheSane
  module Util
    class MavenIdentifier
      attr_accessor :group
      attr_accessor :artifact
      attr_accessor :version
      attr_accessor :classifier
      attr_accessor :extension

      def initialize(string)
        parts = string.match /(?<group>[^:@]+):(?<artifact>[^:@]+):(?<version>[^:@]+)(:(?<classifier>[^:@]+))?(@(?<extension>[^:@]+))?/
        @group = parts[:group]
        @artifact = parts[:artifact]
        @version = parts[:version]
        @classifier = parts[:classifier]
        @extension = parts[:extension] ? parts[:extension] : 'jar'
      end

      def to_path
        path = @group.gsub(/\./, '/') + '/' + @artifact + '/' + @version + '/' + @artifact + '-' + @version
        if @classifier
          path = path + '-' + @classifier
        end
        return path + '.' + @extension
      end

      def to_name
        name = @group + ':' + @artifact + ':' + @version
        if @classifier
          name = name + ':' + @classifier
        end
        if @extension != 'jar'
          name = name + '@' + @extension
        end
        return name
      end
    end
  end
end
