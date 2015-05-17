module WonkoTheSane
  module Util
    class Configuration
      attr_reader :lists
      attr_accessor :data_path

      def register_list(list)
        @lists ||= []
        case list
        when String
          register_list list.to_sym
        when Symbol
          register_list list.constantize
        when Class
          register_list list.new
        else
          @lists << list
        end
      end

      def register_lists_from(file)
        sources = WonkoTheSane.data_json 'sources.json'
        sources[:forgefiles].each do |uid, urlId|
          register_list ForgeFilesModsList.new(uid.to_s, urlId)
        end if sources[:forgefiles]
        sources[:jenkins].each do |obj|
          register_list JenkinsVersionList.new(obj[:uid], obj[:url], obj[:artifact], obj[:fileRegex])
        end if sources[:jenkins]
        sources[:curse].each do |obj|
          register_list CurseVersionList.new(obj[:uid], obj[:id], obj[:fileregex])
        end if sources[:curse]
      end
    end
  end
end
