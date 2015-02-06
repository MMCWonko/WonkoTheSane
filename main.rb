#!/usr/bin/ruby

Dir['./**/*.rb'].each do |file| require file end
require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

#$registry.store ForgeInstallerProfileInput.new('forge').parse(File.read('/home/jan/projects/MultiLaunch/build/src/tmp/1.7.json'), '1.7')
#$registry.store ForgeInstallerProfileInput.new('forge').parse(File.read('/home/jan/projects/MultiLaunch/build/src/tmp/1.8.json'), '1.8')
#$registry.store MojangInput.new('minecraft').parse(File.read('/home/jan/projects/MultiLaunch/build/src/minecraft/jsons/1.4.7.json'))

$vanilla = VanillaVersionList.new
$vanilla.refresh

$forge = ForgeVersionList.new
$forge.refresh