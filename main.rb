#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

Dir.chdir(File.dirname(__FILE__))

Dir['./*.rb'].each do |file| require_relative file end
Dir['./util/*.rb'].each do |file| require_relative file end
Dir['./input/*.rb'].each do |file| require_relative file end
Dir['./versionlists/*.rb'].each do |file| require_relative file end

$modLists = []
{
    'ironchests' => 'IronChests2',
    'biomesoplenty' => 'BiomesOPlenty',
    'codechicken.lib' => 'CodeChickenLib',
    'forgeessentials' => 'ForgeEssentials',
    'forgemultipart' => 'ForgeMultipart',
    'secretroomsmod' => 'SecretRoomsMod',
    'worldcore' => 'WorldCore',
    'compactsolars' => 'CompactSolars'
}.each do |artifact, urlId|
  $modLists << ForgeFilesModsList.new(artifact, urlId)
end
[
    {
        uid: 'ic2',
        url: 'http://jenkins.ic2.player.to',
        artifact: 'IC2_experimental'
    },
    {
        uid: 'dimdoors',
        url: 'http://build.technicpack.net',
        artifact: 'DimDoors'
    },
    {
        uid: 'enderore',
        url: 'http://build.technicpack.net',
        artifact: 'EnderOre'
    },
    {
        uid: 'flatbedrock',
        url: 'http://build.technicpack.net',
        artifact: 'FlatBedrock'
    },
    {
        uid: 'gregslighting',
        url: 'http://build.technicpack.net',
        artifact: 'GregsLighting'
    },
    {
        uid: 'hexxitgear',
        url: 'http://build.technicpack.net',
        artifact: 'HexxitGear'
    },
    {
        uid: 'inventorytweaks',
        url: 'http://build.technicpack.net',
        artifact: 'Inventory-Tweaks'
    },
    {
        uid: 'minefactoryreloaded',
        url: 'http://build.technicpack.net',
        artifact: 'MineFactoryReloaded'
    },
    {
        uid: 'modularpowersuits',
        url: 'http://build.technicpack.net',
        artifact: 'ModularPowersuits'
    },
    {
        uid: 'numina',
        url: 'http://build.technicpack.net',
        artifact: 'Numina'
    },
    {
        uid: 'buildcraft',
        url: 'http://nallar.me/buildservice',
        artifact: 'Buildcraft'
    },
    {
        uid: 'equivalentexchange3',
        url: 'http://nallar.me/buildservice',
        artifact: 'Equivalent%20Exchange%203'
    },
    {
        uid: 'openblocks',
        url: 'http://www.openmods.info:8080',
        artifact: 'OpenBlocks'
    },
    {
        uid: 'openeye',
        url: 'http://www.openmods.info:8080',
        artifact: 'OpenEye'
    },
    {
        uid: 'openmodslib',
        url: 'http://www.openmods.info:8080',
        artifact: 'OpenModsLib'
    },
    {
        uid: 'openperipheralsaddons',
        url: 'http://www.openmods.info:8080',
        artifact: 'OpenPeripheralAddons'
    },
    {
        uid: 'openperipheralscore',
        url: 'http://www.openmods.info:8080',
        artifact: 'OpenPeripheralCore'
    },
    {
        uid: 'openperipheralintegration',
        url: 'http://www.openmods.info:8080',
        artifact: 'OpenPeripheralIntegration'
    },
    {
        uid: 'logisticspipes',
        url: 'http://ci.thezorro266.com',
        artifact: 'LogisticsPipesMC1.2.5'
    },
    {
        uid: 'logisticspipes',
        url: 'http://ci.thezorro266.com',
        artifact: 'LogisticsPipesMC1.3.2'
    },
    {
        uid: 'logisticspipes',
        url: 'http://ci.thezorro266.com',
        artifact: 'LogisticsPipesMC1.4.7'
    },
    {
        uid: 'logisticspipes',
        url: 'http://ci.thezorro266.com',
        artifact: 'LogisticsPipesMC1.5.2'
    },
    {
        uid: 'logisticspipes',
        url: 'http://ci.thezorro266.com',
        artifact: 'LogisticsPipes1.7'
    },
    {
        uid: 'bdlib',
        url: 'http://jenkins.bdew.net',
        artifact: 'bdlib-1.7.10'
    },
    {
        uid: 'bdlib',
        url: 'http://jenkins.bdew.net',
        artifact: 'bdlib-1.7.10'
    },
    {
        uid: 'gendustry',
        url: 'http://jenkins.bdew.net',
        artifact: 'gendustry-1.7.10'
    },
    {
        uid: 'bdew.generators',
        url: 'http://jenkins.bdew.net',
        artifact: 'generators-1.7.10'
    },
    {
        uid: 'neiaddons',
        url: 'http://jenkins.bdew.net',
        artifact: 'neiaddons-1.7.10'
    },
    {
        uid: 'bdew.pressure',
        url: 'http://jenkins.bdew.net',
        artifact: 'pressure-1.7.10'
    }
].each do |obj|
  $modLists << JenkinsVersionList.new(obj[:uid], obj[:url], obj[:artifact])
end

users = {
    'jan' => 'test'
}

$lists = {
    thisErrors: BaseVersionList.new('thisErrors'),
    vanilla: VanillaVersionList.new,
    vanillaLegacy: VanillaLegacyVersionList.new,
    liteloader: LiteLoaderVersionList.new,
    forge: ForgeVersionList.new,
    fml: FMLVersionList.new
}
$modLists.each do |list|
  $lists[list.artifact.to_sym] = list
end

require 'optparse'
options = {
    server: false,
    refreshAll: false
}
OptionParser.new do |opts|
  opts.banner = 'Usage: ./main.rb [options]'
  opts.on '-s', '--server', 'Start the WebSocket/HTTP server' do
    options[:server] = true
  end
  opts.on '-r', '--refresh-all', 'Refreshes all lists' do
    options[:refreshAll] = true
  end
end.parse!

if options[:refreshAll]
  puts 'Refreshing lists...'
  $lists.each_value do |list|
    list.refresh
  end
end

if not options[:server]
  exit 0
end

puts 'Starting server...'

$broadcastChannel = EM::Channel.new
class WonkoHttpServer < EM::Connection
  include EM::HttpServer
  def post_init
    super
    no_environment_strings
  end
  def process_http_request
    response = EM::DelegatedHttpResponse.new(self)
    puts 'Received request for ' + @http_path_info
    if @http_path_info == '/'
      response.status = 200
      response.content_type 'text/html'
      response.content = File.read 'web.html'
    elsif @http_path_info == '/favicon.png'
      response.status = 200
      response.content_type 'image/png'
      response.content = File.read 'favicon.png'
    elsif @http_path_info.start_with? '/api/'
      response.status = 200
      response.content_type 'text/json'
      case @http_path_info.match(/(?<=\/api\/).*/)[0]
        when /^lists$/
          response.content = JSON.generate($lists.map do |artifact, list| {
                                               uid: artifact,
                                               lastModified: list.last_modified,
                                               versions: list.processed.length,
                                               lastError: list.lastError,
                                               running: list.running
                                           } end)
        when /^list\/([^\/]*)$/
          list = $1.to_sym
          obj = if File.exist? VersionIndex.local_filename(list.to_s)
                  JSON.parse File.read(VersionIndex.local_filename(list.to_s))
                else
                  {
                      versions: [],
                      uid: list.to_s
                  }
                end
          obj[:lastModified] = $lists[list].last_modified
          obj[:lastError] = $lists[list].lastError
          obj[:running] = $lists[list].running
          response.content = JSON.generate obj
        when /^list\/([^\/]*)\/refresh$/
          puts 'Will refresh ' + $1
          listId = $1.to_sym
          list = $lists[listId]
          if list
            if not list.running
              $broadcastChannel.push({command: :refreshEnqueued, list: listId})
              list.running = true
              $broadcastChannel.push({command: :listUpdated, list: listId})
              EventMachine.defer do
                list.refresh
                if list.lastError
                  $broadcastChannel.push({command: :refreshError, list: listId, error: list.lastError})
                else
                  $broadcastChannel.push({command: :refreshFinished, list: listId})
                end
                $broadcastChannel.push({command: :listUpdated, list: listId})
              end
            end
            response.content = '{}'
          else
            response.status = 404
            response.content = '{"error": "Unknown list ID"}'
          end
        when /^list\/([^\/]*)\/invalidate/
          listId = $1.to_sym
          $lists[listId].invalidate
          $broadcastChannel.push({command: :listUpdated, list: listId})
        when /^list\/([^\/]*)\/([^\/]*)\/invalidate/
          listId = $1.to_sym
          $lists[listId].invalidate $2
          $broadcastChannel.push({command: :listUpdated, list: listId})
        when /^shutdown$/
          $broadcastChannel.push({command: :shuttingDown})
          EventMachine::WebSocket.stop
          EventMachine.stop
      end
    end
    response.send_response
  end
end

require 'digest/sha2'

EventMachine.run do
  EventMachine.start_server '0.0.0.0', 8080, WonkoHttpServer

  @wsServer = EventMachine::WebSocket.run(host: '0.0.0.0', port: 10081, debug: true) do |ws|
    ws.onopen do
      bcId = nil
      hasAuthed = false

      ws.onmessage do |msg|
        begin
          resp = JSON.parse(msg, symbolize_names: true)
          cmd = resp[:command].to_sym
          if not cmd
            raise 'No command specified'
          end
          if not hasAuthed
            if cmd != :auth
              raise 'You have not authorized yourself yet!'
            elsif users.key? resp[:username] and Digest::SHA512.hexdigest(users[resp[:username]]) == resp[:password]
              hasAuthed = true
              ws.send JSON.generate({command: :authSuccess})
              bcId = $broadcastChannel.subscribe do |msg| ws.send JSON.generate(msg) end
            else
              ws.send JSON.generate({command: :authError, error: 'Invalid username or password'})
              ws.close
            end
          else
            case cmd
              when :ping
                ws.send JSON.generate({command: :pong, timestamp: resp[:timestamp]})
            end
          end
        rescue JSON::ParserError => e
          ws.send JSON.generate({command: :error, error: 'Invalid JSON'})
        rescue Exception => e
          ws.send JSON.generate({command: :error, error: e.message})
          puts e.backtrace
        end
      end
      ws.onclose do
        $broadcastChannel.unsubscribe bcId if bcId
      end
    end
  end
end

exit 0