require 'logging'
require 'colorize'
require 'yajl/json_gem'
require 'fileutils'
require 'zip'
require 'set'
require 'uri'
require 'net/http'
require 'digest'
require 'date'
require 'time'
require 'oga'
require 'pathname'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/blank'

require 'wonko_the_sane/version'
require 'wonko_the_sane/tools/update_nem'
require 'wonko_the_sane/util/benchmark'
require 'wonko_the_sane/util/configuration'
require 'wonko_the_sane/util/extraction_cache'
require 'wonko_the_sane/util/deep_storage_cache'
require 'wonko_the_sane/util/file_hash_cache'
require 'wonko_the_sane/util/http_cache'
require 'wonko_the_sane/util/maven_identifier'
require 'wonko_the_sane/util/task_stack'
require 'wonko_the_sane/util/version_parser'

require 'wonko_the_sane/input/base_input'
require 'wonko_the_sane/input/forge_installer_profile_input'
require 'wonko_the_sane/input/forgefiles_mods_input'
require 'wonko_the_sane/input/jenkins_input'
require 'wonko_the_sane/input/mojang_input'

require 'wonko_the_sane/versionlists/base_version_list'
require 'wonko_the_sane/versionlists/curse_version_list'
require 'wonko_the_sane/versionlists/forge_version_list'
require 'wonko_the_sane/versionlists/forgefiles_mods_list'
require 'wonko_the_sane/versionlists/jenkins_version_list'
require 'wonko_the_sane/versionlists/liteloader_version_list'
require 'wonko_the_sane/versionlists/vanilla_legacy_version_list'
require 'wonko_the_sane/versionlists/vanilla_version_list'

require 'wonko_the_sane/new_format'
require 'wonko_the_sane/old_format'
require 'wonko_the_sane/registry'
require 'wonko_the_sane/rules'
require 'wonko_the_sane/timestamps'
require 'wonko_the_sane/version_index'
require 'wonko_the_sane/wonko_version'

module WonkoTheSane
  def self.lists
    configuration.lists
  end

  def self.tasks
    @tasks ||= WonkoTheSane::Util::TaskStack.new
  end

  def self.data(file)
    Pathname.new(configuration.data_path) + file
  end

  def self.data_json(file)
    res = JSON.parse File.read data file
    res.is_a?(Hash) ? HashWithIndifferentAccess.new(res) : res
  end

  def self.set_data_json(file, obj)
    File.write data(file), JSON.pretty_generate(obj)
  end

  def self.configure(&block)
    yield configuration
  end

  def self.configuration
    @configuration ||= Util::Configuration.new
  end
end

WonkoTheSane.configuration.load_from_file 'wts.yml' if File.exists? 'wts.yml'
WonkoTheSane.configuration.load_from_env
