
require File.expand_path('../support/spec_helper', __FILE__)

# Gems
require 'acpc_poker_types/types/match_state_string'
require 'acpc_poker_types/types/poker_action'

# Local modules
require File.expand_path('../support/dealer_data', __FILE__)

# Local classes
require File.expand_path('../../lib/acpc_poker_basic_proxy/basic_proxy', __FILE__)

describe BasicProxy do
   include DealerData
   
   before(:each) do      
      port_number = 9001
      host_name = 'localhost'
      millisecond_response_timeout = 0
      delaer_info = AcpcDealerInformation.new host_name, port_number, millisecond_response_timeout
      @dealer_communicator = mock 'AcpcDealerCommunicator'
      
      AcpcDealerCommunicator.expects(:new).once.with(port_number, host_name, millisecond_response_timeout).returns(@dealer_communicator)
      
      @patient = BasicProxy.new delaer_info
   end
   
   it 'given a sequence of match states and actions, it properly sends and receives them' do
      DealerData::DATA.each do |num_players, data_by_num_players|
         ((0..(num_players-1)).map{ |i| (i+1).to_s }).each do |seat|
            data_by_num_players.each do |type, data_by_type|
               turns = data_by_type[:actions]
            
               # Sample the dealer match string and action data
               number_of_tests = 100
               number_of_tests.times do |i|
                  turn = turns[i]
                  
                  from_player_message = turn[:from_players]
                  
                  unless from_player_message.empty?
                     seat_taking_action = from_player_message.keys.first
                     
                     if seat_taking_action == seat                        
                        action = PokerAction.new from_player_message[seat_taking_action]
                        
                        ActionSender.expects(:send_action).once.with(@dealer_communicator, @match_state, action)
                        
                        @patient.send_action(action)
                     end
                  end
                  
                  match_state_string = turn[:to_players][seat]                  
                  @dealer_communicator.stubs(:gets).returns(match_state_string)
                  
                  @match_state = MatchStateString.parse match_state_string
                  
                  @patient.receive_match_state_string!.should == @match_state
               end
            end
         end
      end
   end
   
   describe '#send_action' do
      it 'raises an exception if a match state was not received before an action was sent' do
         expect{@patient.send_action(mock('PokerAction'))}.to raise_exception(BasicProxy::InitialMatchStateNotYetReceived)
      end
   end
end