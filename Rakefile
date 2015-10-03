require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :docker do
  desc 'Build the docker image for WonkoTheSane'
  task :build do
    system 'docker build -t 02jandal/wonko_the_sane:latest .'
  end
end
