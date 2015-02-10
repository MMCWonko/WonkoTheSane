#!/usr/bin/ruby

require 'rubygems'
require "bundler/setup"

Dir.chdir(File.dirname(__FILE__))

Dir['./*.rb'].each do |file| require file end
Dir['./util/*.rb'].each do |file| require file end
Dir['./input/*.rb'].each do |file| require file end
Dir['./versionlists/*.rb'].each do |file| require file end

#$registry.store ForgeInstallerProfileInput.new('forge').parse(File.read('/home/jan/projects/MultiLaunch/build/src/tmp/1.7.json'), '1.7')
#$registry.store ForgeInstallerProfileInput.new('forge').parse(File.read('/home/jan/projects/MultiLaunch/build/src/tmp/1.8.json'), '1.8')
#$registry.store MojangInput.new('minecraft').parse(File.read('/home/jan/projects/MultiLaunch/build/src/minecraft/jsons/1.4.7.json'))

$vanilla = VanillaVersionList.new
$vanilla.refresh

$vanillaLegacy = VanillaLegacyVersionList.new
$vanillaLegacy.refresh

$liteloader = LiteLoaderVersionList.new
$liteloader.refresh

$forge = ForgeVersionList.new
$forge.refresh

$fml = FMLVersionList.new
$fml.refresh
