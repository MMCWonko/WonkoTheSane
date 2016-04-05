require_relative '../base_source'
require 'active_support'
module WonkoTheSane::Sources
  class Curse < WonkoTheSane::Source
    def run!
      login!
      @addon_ids.each { |id| process! id }
    end

    protected
    def configure
      @addon_ids = config.fetch :addons
      @username  = config.fetch :username
      @password  = config.fetch :password

      @curse_api = Faraday.new 'https://curse-rest-proxy.azurewebsites.net/api' do |conn|
        conn.request :json
        conn.response :json

        conn.adapter Faraday.default_adapter
      end
    end

    private
    def login!
      resp = @curse_api.post '/authenticate', { username: @username, password: @password }
      case resp.status
        when 401
          return :auth_failed
        when 400
          return :bad_request
        when 200
          session = resp.body['session']
          tok     = session['token']
          uid     = session['uid']
          @curse_api.authorization :Token, "#{uid}:#{tok}"
        else
          return :unknown_error
      end
    end

    def process!(id)
      resp     = @curse_api.get "/addon/#{id}"
      package  = {
          formatVersion: 0,
          uid:           resp['name'].underscore.to_sym,
          name:          resp['name']
      }
      files    = @curse_api.get("/addon/#{id}/files")['files']
      versions = files.filter { |f| !f['is_alternate'] }.map do |file|
        version           = {}.merge(package)
        version[:version] = file['file_name']
        version[:data]    = { 'general.downloads':
                                  [{
                                       url:         file['download_url'],
                                       destination: "#{resp['category_section']['path']}/#{file['file_name_on_disk']}",
                                       size:        nil,
                                       sha256:      nil
                                   }] }
        version[:requires] = [] #TODO: Dependency handling. It's harder
        version[:type] = nil
      end
      versions.each do |v|
        break unless [200, 201].include? wonko_core.post('/versions/new', v).status
      end
    end
  end
end