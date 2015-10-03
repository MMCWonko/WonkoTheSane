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
        @extension = parts[:extension] || 'jar'
      end

      def to_path
        path = "#{@group.gsub /\./, '/'}/#{@artifact}/#{@version}/#{@artifact}-#{@version}"
        path = "#{path}-#{@classifier}" if @classifier
        "#{path}.#{@extension}"
      end

      def to_name
        name = "#{@group}:#{@artifact}:#{@version}"
        name = "#{name}:#{@classifier}" if @classifier
        name = "#{name}@#{@extension}" if @extension != 'jar'
        name
      end
    end
  end
end
