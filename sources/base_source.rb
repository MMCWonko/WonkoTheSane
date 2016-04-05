require 'faraday'
require 'faraday_middleware'

module WonkoTheSane
  class Source
    attr_reader :config, :wonko_core

    def initialize(config = {})
      @config = config
      @wonko_core = Faraday.new config.fetch(:url) do |conn|
        conn.request :json
        conn.response :json

        conn.adapter Faraday.default_adapter
      end
      configure
    end

    def run!
      raise :subclass_responsibility
    end

    protected

    def configure

    end

  end
end