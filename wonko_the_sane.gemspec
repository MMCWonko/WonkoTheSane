lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wonko_the_sane/version'

Gem::Specification.new do |spec|
  spec.name = 'wonko_the_sane'
  spec.version = WonkoTheSane::VERSION
  spec.authors = ['02JanDal', 'robotbrain', 'peterix']
  spec.email = ['jan@dalheimer.de', 'robotbrain@robotbrain.info', 'peterix@gmail.com']
  spec.summary = 'Pre-processing and format-unification of various resources mainly related to Minecraft'
  spec.homepage = 'https://github.com/MultiMC/WonkoTheSane'
  spec.license = 'MIT'

  spec.files = Dir['lib/**/*.rb'] + Dir['data/**/*']
  spec.bindir = 'bin'
  spec.executables = ['wonko_the_sane']
  spec.test_files = Dir['tests/test_*.rb']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-shell'

  spec.add_runtime_dependency 'rubyzip'
  spec.add_runtime_dependency 'yajl-ruby'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'oga'
  spec.add_runtime_dependency 'logging'
  spec.add_runtime_dependency 'aws-sdk'
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'faraday-http-cache'
  spec.add_runtime_dependency 'faraday-request-timer'
  spec.add_runtime_dependency 'faraday_middleware'
  spec.add_runtime_dependency 'faraday-cookie_jar'
  spec.add_runtime_dependency 'faraday_connection_pool'
end
