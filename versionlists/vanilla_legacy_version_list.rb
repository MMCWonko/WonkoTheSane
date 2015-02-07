require_relative 'base_version_list'

class VanillaLegacyVersionList < BaseVersionList
  def initialize
    super('net.minecraft')
  end

  def get_versions
    result = BaseVersionList.get_json 'https://cdn.rawgit.com/MultiMC/MultiMC5/develop/resources/versions/minecraft.json'
    return result[:versions].map do |obj| [obj[:id], obj] end
  end

  @@versionNameIdMapping = {
      'b1.8.1' => '0.3.26',
      'b1.8' => '0.3.25',
      'b1.7.3' => '0.3.24',
      'b1.7.2' => '0.3.23',
      'b1.7' => '0.3.22',
      'b1.6.6' => '0.3.21',
      'b1.6.5' => '0.3.20',
      'b1.6.4' => '0.3.19',
      'b1.6.3' => '0.3.18',
      'b1.6.2' => '0.3.17',
      'b1.6.1' => '0.3.16',
      'b1.6' => '0.3.15',
      'b1.5_01' => '0.3.14',
      'b1.5' => '0.3.13',
      'b1.4_01' => '0.3.12',
      'b1.4' => '0.3.11',
      'b1.3_01' => '0.3.10',
      'b1.3b' => '0.3.9',
      'b1.2_02' => '0.3.8',
      'b1.2_01' => '0.3.7',
      'b1.2' => '0.3.6',
      'b1.1_02' => '0.3.5',
      'b1.1_01' => '0.3.4',
      'b1.0.2' => '0.3.3',
      'b1.0_01' => '0.3.2',
      'b1.0' => '0.3.1',
      'a1.2.6' => '0.2.25',
      'a1.2.5' => '0.2.24',
      'a1.2.4_01' => '0.2.23',
      'a1.2.3_04' => '0.2.22',
      'a1.2.3_02' => '0.2.21',
      'a1.2.3_01' => '0.2.20',
      'a1.2.3' => '0.2.19',
      'a1.2.2b' => '0.2.18',
      'a1.2.2a' => '0.2.17',
      'a1.2.1_01' => '0.2.16',
      'a1.2.1' => '0.2.15',
      'a1.2.0_02' => '0.2.14',
      'a1.2.0_01' => '0.2.13',
      'a1.2.0' => '0.2.12',
      'a1.1.2_01' => '0.2.11',
      'a1.1.2' => '0.2.10',
      'a1.1.0' => '0.2.9',
      'a1.0.17_04' => '0.2.8',
      'a1.0.17_02' => '0.2.7',
      'a1.0.16' => '0.2.6',
      'a1.0.15' => '0.2.5',
      'a1.0.14' => '0.2.4',
      'a1.0.11' => '0.2.3',
      'a1.0.5_01' => '0.2.2',
      'a1.0.4' => '0.2.1',
      'inf-20100618' => '0.1.5',
      'c0.30_01c' => '0.1.4',
      'c0.0.13a_03' => '0.1.3',
      'c0.0.13a' => '0.1.2',
      'c0.0.11a' => '0.1.1',
      'rd-161348' => '0.0.4',
      'rd-160052' => '0.0.3',
      'rd-132328' => '0.0.2',
      'rd-132211' => '0.0.1'
  }

  def get_version(id)
    data = id[1]
    file = Version.new
    file.uid = 'net.minecraft'
    if @@versionNameIdMapping.has_key? data[:id]
      file.versionId = @@versionNameIdMapping[data[:id]]
      file.versionName = data[:id]
    else
      file.versionId = data[:id]
    end
    file.time = data[:releaseTime]
    file.type = data[:type]
    file.traits = data[:'+traits']
    file.extra[:processArguments] = data[:processArguments]
    file.mainClass = data[:mainClass] if data.has_key? :mainClass
    file.appletClass = data[:appletClass] if data.has_key? :appletClass

    BaseSanitizer.sanitize file, MojangProcessArgumentsSanitizer
  end
end