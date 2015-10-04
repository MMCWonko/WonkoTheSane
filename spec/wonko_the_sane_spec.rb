require 'spec_helper'

describe WonkoTheSane do
  it 'has a version number' do
    expect(WonkoTheSane::VERSION).not_to be nil
    expect(WonkoTheSane::VERSION).to match /\d+\.\d+\.\d/
  end

  it('provides data') { expect(WonkoTheSane.data_json 'timestamps.json').to be_a Hash }
  it 'consumes data' do
    filename = WonkoTheSane.data 'test.json'
    File.delete filename if File.exists? filename
    WonkoTheSane.set_data_json 'test.json', {'a': 'b'}
    expect(WonkoTheSane.data_json 'test.json').to eq({'a' => 'b'})
    File.delete filename
  end

  context '#configure' do
    it 'yields' do
      expect { |b| WonkoTheSane.configure &b }.to yield_control.once
      expect { |b| WonkoTheSane.configure &b }.to yield_with_args(WonkoTheSane.configuration)
    end
  end

  context '#configuration' do
    it 'returns a valid object' do
      expect(WonkoTheSane.configuration).to be_a WonkoTheSane::Util::Configuration
    end
  end

  context '#lists' do
    it 'is a shortcut to #configuration#lists' do
      expect(WonkoTheSane.lists).to eq WonkoTheSane.configuration.lists
    end
  end
end
