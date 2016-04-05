require 'yajl'
require 'wonkothesane/json_middleware'

module WonkoTheSane::Format
  def verify_wonko_version(version)
    false unless version.key? :formatVersion
    false unless version.key? :uid
    false unless version.key? :version
    false unless version.key? :data
    true
  end
end