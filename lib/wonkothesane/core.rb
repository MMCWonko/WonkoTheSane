require 'sinatra/base'
require 'wonkothesane/format'
require 'wonkothesane/storage'

module WonkoTheSane
  class Core < Sinatra::Base
    include WonkoTheSane::Format
    use Rack::JsonPostBody

    def initialize(app = nil, options = {})
      super(app)
      @storage = Storage.new(options.fetch(:storage))
    end

    post '/version/new' do
      msg = env[JsonPostBody::FORM_HASH]
      break [400, '{"msg": "Invalid version file!"}'] unless verify_wonko_version msg
      break [500, '{"msg": "Error adding version file"}'] unless @storage.register_version(msg)
      '{"msg": "OK"}'
    end

    get '/version/:uid/:ver' do
      Yajl::Encoder.encode(@storage.get_version(@params[:uid], @params[:ver]))
    end
  end
end