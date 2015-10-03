require 'yaml'

module WonkoTheSane
  module Util
    class Configuration
      class Aws
        attr_accessor :client_id
        attr_accessor :client_secret
        attr_accessor :bucket
      end

      attr_reader :aws
      attr_reader :wonkoweb
      attr_reader :lists
      attr_accessor :data_path
      attr_accessor :out_dir

      def initialize
        @lists = []
        @aws = Aws.new
      end

      def load_from_env
        @aws.client_id = ENV['WTS_AWS_CLIENT_ID'] if ENV['WTS_AWS_CLIENT_ID']
        @aws.client_secret = ENV['WTS_AWS_CLIENT_SECRET'] if ENV['WTS_AWS_CLIENT_SECRET']
        @aws.bucket = ENV['WTS_AWS_BUCKET'] if ENV['WTS_AWS_BUCKET']

        @data_path = ENV['WTS_DATA_PATH'] if ENV['WTS_DATA_PATH']
        @out_dir = ENV['WTS_OUT_DIR'] if ENV['WTS_OUT_DIR']
      end

      def load_from_file(filename)
        raw = YAML.load_file filename
        @aws.client_id = raw['aws']['client_id']
        @aws.client_secret = raw['aws']['client_secret']
        @aws.bucket = raw['aws']['bucket']

        @data_path = raw['data_path']
        @out_dir = raw['out_dir']
      end

      def register_list(list)
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

      def register_lists_from_sources
        sources = WonkoTheSane.data_json 'sources.json'
        sources[:forgefiles].each do |uid, urlId|
          register_list ForgeFilesModsList.new(uid.to_s, urlId)
        end if sources[:forgefiles]
        sources[:jenkins].each do |obj|
          register_list JenkinsVersionList.new(obj[:uid], obj[:url], obj[:artifact], obj[:@file_regex])
        end if sources[:jenkins]
        sources[:curse].each do |obj|
          register_list CurseVersionList.new(obj[:uid], obj[:id], obj[:fileregex])
        end if sources[:curse]
      end
    end
  end
end
