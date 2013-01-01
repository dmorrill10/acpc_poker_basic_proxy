
require 'simplecov'
SimpleCov.start

require 'mocha'

RSpec.configure do |config|
   # == Mock Framework
   config.mock_with :mocha
end

# Match log information in dealer_logs
class MatchLog
  DEALER_LOG_DIRECTORY = File.expand_path('../dealer_logs', __FILE__)

  attr_reader :results_file_name, :actions_file_name, :player_names, :dealer_log_directory

  def initialize(results_file_name, actions_file_name, player_names)
    @results_file_name = results_file_name
    @actions_file_name = actions_file_name
    @player_names = player_names
  end
  
  def actions_file_path
    "#{DEALER_LOG_DIRECTORY}/#{@actions_file_name}"
  end

  def results_file_path
    "#{DEALER_LOG_DIRECTORY}/#{@results_file_name}"
  end
end

def match_logs
  [
    MatchLog.new(
      '2p.limit.h1000.r0.log',
      '2p.limit.h1000.r0.actions.log',
      ['p1', 'p2']
    ),
    MatchLog.new(
      '2p.nolimit.h1000.r0.log',
      '2p.nolimit.h1000.r0.actions.log',
      ['p1', 'p2']
    ),
    MatchLog.new(
      '3p.limit.h1000.r0.log',
      '3p.limit.h1000.r0.actions.log',
      ['p1', 'p2', 'p3']
    ),
    MatchLog.new(
      '3p.nolimit.h1000.r0.log',
      '3p.nolimit.h1000.r0.actions.log',
      ['p1', 'p2', 'p3']
    )
  ]
end