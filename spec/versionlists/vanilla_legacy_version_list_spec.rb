require 'spec_helper'

require 'wonko_the_sane/versionlists/vanilla_legacy_version_list'

describe VanillaLegacyVersionList do
  let(:list) { described_class.new }
  let(:versions) { list.get_versions }

  it '#get_versions' do
    expect { list.get_versions }.not_to raise_error
    expect(list.get_versions.size).to be > 10
  end

  context '#get_version' do
    it 'for rd-132211' do
      expect { list.get_version versions.find { |v| v[0] == 'rd-132211' } }.not_to raise_error
    end
    it '1.5.2' do
      expect { list.get_version versions.find { |v| v[0] == '1.5.2' } }.not_to raise_error
    end
    it 'b1.4' do
      expect { list.get_version versions.find { |v| v[0] == 'b1.4' } }.not_to raise_error
    end
    it 'a1.2.6' do
      expect { list.get_version versions.find { |v| v[0] == 'a1.2.6' } }.not_to raise_error
    end
  end
end
