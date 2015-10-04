require 'spec_helper'

require 'yaml'

require 'wonko_the_sane/util/configuration'

describe WonkoTheSane::Util::Configuration do
  let(:config) { described_class.new }

  it '#load_from_env' do
    ENV['WTS_AWS_CLIENT_ID'] = 'a'
    ENV['WTS_AWS_CLIENT_SECRET'] = 'b'
    ENV['WTS_AWS_BUCKET'] = 'c'
    ENV['WTS_DATA_PATH'] = 'd'
    ENV['WTS_OUT_DIR'] = 'e'
    config.load_from_env

    expect(config.aws.client_id).to eq 'a'
    expect(config.aws.client_secret).to eq 'b'
    expect(config.aws.bucket).to eq 'c'
    expect(config.data_path).to eq 'd'
    expect(config.out_dir).to eq 'e'

    ENV['WTS_AWS_CLIENT_ID'] = nil
    ENV['WTS_AWS_CLIENT_SECRET'] = nil
    ENV['WTS_AWS_BUCKET'] = nil
    ENV['WTS_DATA_PATH'] = nil
    ENV['WTS_OUT_DIR'] = nil
  end

  it '#load_from_file' do
    file = Tempfile.new 'wts'
    file.write YAML.dump({
                           aws: {
                             client_id: 'a',
                             client_secret: 'b',
                             bucket: 'c'
                           },
                           data_path: 'd',
                           out_dir: 'e'
                         })
    file.close
    config.load_from_file file.path

    expect(config.aws.client_id).to eq 'a'
    expect(config.aws.client_secret).to eq 'b'
    expect(config.aws.bucket).to eq 'c'
    expect(config.data_path).to eq 'd'
    expect(config.out_dir).to eq 'e'
  end

  context '#register_list' do
    it 'takes a string' do
      config.register_list 'Array'
      expect(config.lists.first).to be_a Array
    end

    it 'takes a symbol' do
      config.register_list :Array
      expect(config.lists.first).to be_a Array
    end

    it 'takes a class' do
      config.register_list Array
      expect(config.lists.first).to be_a Array
    end

    it 'takes an instance' do
      config.register_list []
      expect(config.lists.first).to be_a Array
    end

    it 'adds a list' do
      expect { config.register_list Array }.to change(config.lists, :size).by 1
    end
  end

  context '#register_lists_from_sources' do
    it 'loads from file' do
      file = Tempfile.new 'wts'
      file.write '{}'
      file.close
      expect { config.register_lists_from_sources file.path }.to change(config.lists, :size).by 0
    end

    it 'loads lists' do
      expect {
        config.register_lists_from_sources({
                                             forgefiles: {ironchests: 'IronChests2'},
                                             jenkins: [{
                                                         uid: 'ic2',
                                                         url: 'http://jenkins.ic2.player.to',
                                                         artifact: 'IC2_experimental'
                                                       }],
                                             curse: [{
                                                       uid: 'compactmachines',
                                                       id: '224218',
                                                       fileregex: 'compactmachines-(?P<mc>.+?)-(?P<version>.+?).jar$'
                                                     }]
                                           })
      }.to change(config.lists, :size).by 3
      expect(config.lists[0].artifact).to eq 'ironchests'
      expect(config.lists[1].artifact).to eq 'ic2'
      expect(config.lists[2].artifact).to eq 'compactmachines'
    end
  end
end
