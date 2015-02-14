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
$modLists.each do |list|
  list.refresh
end

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
