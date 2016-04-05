# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wonkothesane/version'

Gem::Specification.new do |spec|
  spec.name          = "wonkothesane"
  spec.version       = WonkoTheSane::VERSION
  spec.authors       = ["Alexia"]
  spec.email         = ["alexia@robotbrain.info"]

  spec.summary       = %q{Version repository core, designed for minecraft but not limited thereto}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'sinatra', '~> 1.4.7'
  spec.add_dependency 'yajl-ruby', '~> 1.2.1'
  spec.add_dependency 'rugged', '~> 0.24.0'
end
