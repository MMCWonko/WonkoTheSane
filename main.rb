#!/usr/bin/ruby

require 'rubygems'
require "bundler/setup"

Dir.chdir(File.dirname(__FILE__))

Dir['./*.rb'].each do |file| require file end
Dir['./util/*.rb'].each do |file| require file end
Dir['./input/*.rb'].each do |file| require file end
Dir['./versionlists/*.rb'].each do |file| require file end

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
