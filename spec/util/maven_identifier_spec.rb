require 'spec_helper'

describe WonkoTheSane::Util::MavenIdentifier do
  context 'the.group:artifact:1.2.3' do
    let(:identifier) { described_class.new 'the.group:artifact:1.2.3' }

    it 'has a path of the.group/artifact/artifact-1.2.3.jar' do
      expect(identifier.to_path).to eq 'the/group/artifact/1.2.3/artifact-1.2.3.jar'
    end

    it 'has a name of the.group:artifact:1.2.3' do
      expect(identifier.to_name).to eq 'the.group:artifact:1.2.3'
    end
  end

  context 'the.group:artifact:1.2.3:classifier@zip' do
    let(:identifier) { described_class.new 'the.group:artifact:1.2.3:classifier@zip' }

    it 'has a path of the.group/artifact/artifact-1.2.3-classifier.zip' do
      expect(identifier.to_path).to eq 'the/group/artifact/1.2.3/artifact-1.2.3-classifier.zip'
    end

    it 'has a name of the.group:artifact:1.2.3:classifier@zip' do
      expect(identifier.to_name).to eq 'the.group:artifact:1.2.3:classifier@zip'
    end
  end
end
