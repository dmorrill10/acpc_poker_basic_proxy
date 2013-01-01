$:.push File.expand_path("../lib", __FILE__)
require "acpc_poker_basic_proxy/version"

Gem::Specification.new do |s|
  s.name        = "acpc_poker_basic_proxy"
  s.version     = AcpcPokerBasicProxy::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = "https://github.com/dmorrill10/acpc_poker_basic_proxy"
  s.summary     = %q{ACPC Poker Basic Proxy}
  s.description = %q{Basic proxy to connect to the ACPC Dealer.}
  
  s.add_dependency 'acpc_poker_types'
  s.add_dependency 'dmorrill10-utils'
  
  s.rubyforge_project = "acpc_poker_basic_proxy"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("ext/**/*") + %w(Rakefile acpc_poker_basic_proxy.gemspec tasks.rb README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'acpc_dealer_data'
  s.add_development_dependency 'acpc_dealer'
end
