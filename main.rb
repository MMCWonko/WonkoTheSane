#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

Dir.chdir(File.dirname(__FILE__))

Dir['./*.rb'].each do |file| require_relative file end
Dir['./util/*.rb'].each do |file| require_relative file end
Dir['./input/*.rb'].each do |file| require_relative file end
Dir['./versionlists/*.rb'].each do |file| require_relative file end

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

require 'optparse'
OptionParser.new do |opts|
  opts.banner = 'Usage: main.rb [options]'

  opts.on '-rID', '--refresh=ID', 'Refresh the specified list' do |id|
    foundList = false
    lists.each do |list|
      if list.artifact == id
        puts "Refreshing #{list.artifact.cyan}"
        list.refresh
        puts "Error: #{list.lastError.red}" if list.lastError
        foundList = true
      end
    end

    puts "Couldn't find the specified list #{id.cyan}" if not foundList
  end
  opts.on '-a', '--refresh-all', 'Refresh all lists' do
    lists.each do |list|
      puts "Refreshing #{list.artifact.cyan}"
      list.refresh
    end
  end
  opts.on '--invalidate=ID', 'Invalidates all versions on the specified list' do |id|
    foundList = false
    lists.each do |list|
      if list.artifact == id
        puts "Invalidating #{list.artifact.cyan}"
        list.invalidate
        foundList = true
      end
    end

    puts "Couldn't find the specified list #{id.cyan}" if not foundList
  end
  opts.on '--invalidate-all', 'Invalidates all versions on all lists' do
    lists.each do |list|
      puts "Invalidating #{list.artifact.cyan}"
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
