
require File.expand_path('../../support/spec_helper', __FILE__)

require 'acpc_poker_types/types/match_state_string'

# Local modules
require File.expand_path('../../support/dealer_data', __FILE__)

# Local classes
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/match_state_string_receiver', __FILE__)
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator', __FILE__)

describe MatchStateStringReceiver do   
   before(:each) do
      @connection = mock 'AcpcDealerCommunicator'
   end
   
   describe "#receive_matchstate_string" do
      it 'receives matchstate strings properly' do
         DealerData::DATA.each do |num_players, data_by_num_players|
            data_by_num_players.each do |type, data_by_type|
               turns = data_by_type[:actions]
               
               # Sample the dealer match string data
               number_of_tests = 100
               number_of_tests.times do |i|
                  to_player_message = turns[i * (turns.length/number_of_tests)][:to_players]
                  
                  to_player_message.each do |seat, match_state|
                     
                     @connection.expects(:gets).once.returns(match_state)
                     
                     MatchStateStringReceiver.receive_matchstate_string(@connection).should == MatchStateString.parse(match_state)
                  end
               end
            end
         end
      end
   end
end
