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
end
sources[:jenkins].each do |obj|
  lists << JenkinsVersionList.new(obj[:uid], obj[:url], obj[:artifact])
end

lists << VanillaVersionList.new
lists << VanillaLegacyVersionList.new
lists << LiteLoaderVersionList.new
lists << ForgeVersionList.new
lists << FMLVersionList.new

require 'optparse'
OptionParser.new do |opts|
  opts.banner = 'Usage: main.rb [options]'

  opts.on '-rID', '--refresh=ID', 'Refresh the specified list' do |id|
    lists.each do |list|
      list.refresh if list.artifact == id
    end
  end
  opts.on '-a', '--refresh-all', 'Refresh all lists' do
    lists.each do |list| list.refresh end
  end
  opts.on '--invalidate=ID', 'Invalidates all versions on the specified list' do |id|
    lists.each do |list|
      list.invalidate if list.artifact == id
    end
  end
  opts.on '--invalidate-all', 'Invalidates all versions on all lists' do
    lists.each do |list| list.invalidate end
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
