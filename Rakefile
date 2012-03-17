require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core/rake_task'

require File.expand_path('../lib/acpc_poker_basic_proxy/version', __FILE__)
require File.expand_path('../tasks', __FILE__)

include Tasks

RSpec::Core::RakeTask.new(:spec) do |t|
   ruby_opts = "-w"
end

task :build => :spec do
   system "gem build acpc_poker_basic_proxy.gemspec"
end

task :tag => :build do
   tag_gem_version AcpcPokerBasicProxy::VERSION
end

task :install => :build do
end

#desc "release gem to gemserver"
#task :release => [:tag, :deploy] do
#  puts "congrats, the gem is now tagged, pushed, deployed and released! Rember to up the VERSION number"
#end

#task :deploy do
#  puts "Deploying to gemserver@mygemserver.mycompany.com"
#  system "scp my_private_gem-#{AcpcPokerType::VERSION}.gem gemserver@mygemserver.mycompany.com:gems/."
#  puts "installing on gemserver"
#  system "ssh gemserver@mygemserver.mycompany.com \"cd gems && gem install my_private_gem-#{AcpcPokerType::VERSION}.gem --ignore-dependencies\""
#end
