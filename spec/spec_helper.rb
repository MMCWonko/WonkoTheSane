$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'wonko_the_sane'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
