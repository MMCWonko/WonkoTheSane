#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

Dir.chdir(File.dirname(__FILE__))

Logging.color_scheme 'bright',
                     levels: {
                         debug: :gray,
                         info: :green,
                         warn: :yellow,
                         error: :red,
                         fatal: [:white, :on_red]
                     },
                     date: :blue,
                     logger: :cyan
Logging.appenders.stdout 'stdout',
                         layout: Logging.layouts.pattern(pattern: '[%d] %-5l %c: %m\n', color_scheme: 'bright'),
                         level: :debug
Logging.appenders.file 'file', filename: 'wonko.log', pattern: Logging.layouts.pattern(pattern: '[%d] %-5l %c: %m\n')
Logging.logger.root.add_appenders 'stdout', 'file'

Dir['./*.rb'].each do |file| require_relative file if !file.include?('main.rb') end
Dir['./util/*.rb'].each do |file| require_relative file end
Dir['./input/*.rb'].each do |file| require_relative file end
Dir['./versionlists/*.rb'].each do |file| require_relative file end

Logging.logger['General'].info 'Welcome to WonkoTheSane!'.yellow

lists = []

sources = JSON.parse File.read('sources.json'), symbolize_names: true
sources[:forgefiles].each do |uid, urlId|
  lists << ForgeFilesModsList.new(uid.to_s, urlId)
end if sources[:forgefiles]
sources[:jenkins].each do |obj|
  lists << JenkinsVersionList.new(obj[:uid], obj[:url], obj[:artifact], obj[:fileRegex])
end if sources[:jenkins]
sources[:curse].each do |obj|
  lists << CurseVersionList.new(obj[:uid], obj[:id], obj[:fileregex])
end if sources[:curse]

lists << VanillaVersionList.new
lists << VanillaLegacyVersionList.new
lists << LiteLoaderVersionList.new
lists << ForgeVersionList.new
lists << FMLVersionList.new
$globalLists = lists

class TaskStack
  @@queue = []
  def self.push(task)
    @@queue.push task
  end
  def self.push_defered(task)
    @@queue.unshift task
  end
  def self.pop
    task = @@queue.pop
    task.call
  end
  def self.pop_all
    self.pop until @@queue.empty?
  end
end

require 'optparse'
OptionParser.new do |opts|
  opts.banner = 'Usage: main.rb [options]'

  opts.on '-rID', '--refresh=ID', 'Refresh the specified list' do |id|
    foundList = false
    lists.each do |list|
      if list.artifact == id
        TaskStack.push(Proc.new do
                         Logging.logger[list.artifact].info 'Refreshing'
                         list.refresh
                         Logging.logger[list.artifact].error list.lastError if list.lastError
                       end)
        foundList = true
      end
    end

    Logging.logger['General'].warn "Couldn't find the specified list #{id.cyan}" if !foundList
  end
  opts.on '-a', '--refresh-all', 'Refresh all lists' do
    lists.each do |list|
      TaskStack.push(Proc.new do
                       Logging.logger[list.artifact].info 'Refreshing'
                       list.refresh
                       Logging.logger[list.artifact].error list.lastError if list.lastError
                     end)
    end
  end
  opts.on '--invalidate=ID', 'Invalidates all versions on the specified list' do |id|
    foundList = false
    lists.each do |list|
      if list.artifact == id
        Logging.logger[list.artifact].info 'Invalidating'
        list.invalidate
        foundList = true
      end
    end

    Logging.logger['General'].warn "Couldn't find the specified list #{id.cyan}" if !foundList
  end
  opts.on '--invalidate-all', 'Invalidates all versions on all lists' do
    lists.each do |list|
      Logging.logger[list.artifact].info 'Invalidating'
      list.invalidate
    end
  end
  opts.on '--list-all', 'Shows which list IDs are available' do
    lists.each do |list|
      puts list.artifact
    end
  end
  opts.on '--update-nem', 'Updates sources.json with data from NEM' do
    require_relative 'update_nem'
    update_nem
  end
  opts.on '-h', '--help', 'Prints this help' do
    puts opts
    exit
  end
end.parse!

TaskStack.pop_all