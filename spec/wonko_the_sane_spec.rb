require 'spec_helper'

describe WonkoTheSane do
  it 'has a version number' do
    expect(WonkoTheSane::VERSION).not_to be nil
    expect(WonkoTheSane::VERSION).to match /\d+\.\d+\.\d/
  end
end
