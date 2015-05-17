require 'logging'
require 'colorize'
require 'yajl/json_gem'

require 'wonko_the_sane/version'
require 'wonko_the_sane/util/cache'
require 'wonko_the_sane/util/configuration'
require 'wonko_the_sane/util/maven_identifier'
require 'wonko_the_sane/util/task_stack'
require 'wonko_the_sane/tools/update_nem'

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

require 'wonko_the_sane/reader_writer'
require 'wonko_the_sane/registry'
require 'wonko_the_sane/rules'
require 'wonko_the_sane/timestamps'
require 'wonko_the_sane/version_index'
require 'wonko_the_sane/version_parser'
require 'wonko_the_sane/wonko_version'

module WonkoTheSane
  def self.lists
    configuration.lists
  end

  def self.data(file)
    configuration.data_path + '/' + file
  end

  def self.data_json(file)
    JSON.parse File.open(data(file), 'r'), symbolize_keys: true
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
  private_class_method :configuration
end
