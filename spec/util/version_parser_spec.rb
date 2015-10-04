require 'spec_helper'

require 'wonko_the_sane/util/version_parser'

include WonkoTheSane::Util

describe WonkoTheSane::Util::VersionParser do
  context '.compare' do
    it 'compares equal versions' do
      expect(VersionParser.compare '1', '1').to eq 0
      expect(VersionParser.compare '1', '1.0.0').to eq 0
      expect(VersionParser.compare '1.2', '1.2').to eq 0
      expect(VersionParser.compare '2.1', '2.1').to eq 0
      expect(VersionParser.compare '123.456', '123.456').to eq 0
      # various variants of appendix aliases
      expect(VersionParser.compare '42.1-beta', '42.1-beta').to eq 0
      expect(VersionParser.compare '42.1-beta1', '42.1-beta1').to eq 0
      expect(VersionParser.compare '42.1-b', '42.1-beta').to eq 0
      expect(VersionParser.compare '42.1-a', '42.1-alpha').to eq 0
      expect(VersionParser.compare '42.1-pre', '42.1-rc').to eq 0
    end

    it 'compares less than versions' do
      expect(VersionParser.compare '1', '2').to eq -1
      expect(VersionParser.compare '1', '1.0.1').to eq -1
      expect(VersionParser.compare '1.2', '1.3').to eq -1
      expect(VersionParser.compare '2.1', '2.2').to eq -1
      expect(VersionParser.compare '123.456', '124.456').to eq -1
      # various variants of appendixes
      expect(VersionParser.compare '42.1-beta', '42.1').to eq -1
      expect(VersionParser.compare '42.1-alpha', '42.1-beta').to eq -1
      expect(VersionParser.compare '42.1-beta', '42.1-rc').to eq -1
      expect(VersionParser.compare '42.1-rc', '42.1').to eq -1
      expect(VersionParser.compare '42.1-beta', '42.1-beta1').to eq -1
      expect(VersionParser.compare '42.1-beta1', '42.1-beta2').to eq -1
    end

    it 'compares greater than versions' do
      expect(VersionParser.compare '2', '1').to eq 1
      expect(VersionParser.compare '1.0.1', '1').to eq 1
      expect(VersionParser.compare '1.3', '1.2').to eq 1
      expect(VersionParser.compare '2.2', '2.1').to eq 1
      expect(VersionParser.compare '124.456', '123.456').to eq 1
      expect(VersionParser.compare '42.1', '42.1-beta').to eq 1
    end
  end

  context('.less?') { it('compares less than') { expect(VersionParser.less? '1', '2').to eq true } }
  context('.greater?') { it('compares greater than') { expect(VersionParser.greater? '2', '1').to eq true } }
  context('.equal?') { it('compares equal') { expect(VersionParser.equal? '1', '1').to eq true } }
  context('.less_or_equal?') { it('compares less than or equal') { expect(VersionParser.less_or_equal? '1', '2').to eq true } }
  context('.greater_or_equal?') { it('compares greater than or equal') { expect(VersionParser.greater_or_equal? '2', '2').to eq true } }
  context('.not_equal?') { it('compares not equal') { expect(VersionParser.not_equal? '1', '2').to eq true } }
end
