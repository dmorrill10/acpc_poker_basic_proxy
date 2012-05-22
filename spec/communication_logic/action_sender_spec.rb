
require File.expand_path('../../support/spec_helper', __FILE__)

require 'acpc_poker_types/types/poker_action'
require 'acpc_poker_types/types/match_state_string'

# Local modules
require File.expand_path('../../support/dealer_data', __FILE__)

# Local classes
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/action_sender', __FILE__)

describe ActionSender do
   include AcpcPokerTypesDefs
   include DealerData
   
   before(:each) do
      @connection = mock 'AcpcDealerCommunicator'
      @mock_action = mock 'PokerAction'
      @match_state = MatchStateString.parse DealerData::DATA[2][:limit][:actions].first[:to_players]['1']
   end
   
   describe "#send_action" do
      it 'does not send an illegal action and raises an exception' do
         @mock_action.stubs(:to_acpc).returns('illegal action format')
         expect{ActionSender.send_action(@connection, @match_state, @mock_action)}.to raise_exception(ActionSender::IllegalActionFormat)
      end
      it 'raises an exception if the given match state does not have the proper format' do
         @match_state = 'illegal match state format'
         expect{ActionSender.send_action(@connection, @match_state, @mock_action)}.to raise_exception(ActionSender::IllegalMatchStateFormat)
      end
      it 'can send all legal actions through the provided connection without a modifier' do
         PokerAction::LEGAL_ACPC_CHARACTERS.each do |action|
            @mock_action.stubs(:to_acpc).returns(action)
            action_that_should_be_sent = @match_state.to_s + ":#{action}"
            @connection.expects(:write).once.with(action_that_should_be_sent)
         
            ActionSender.send_action @connection, @match_state, @mock_action
         end
      end
      it 'does not send legal unmodifiable actions that have a modifier and raises an exception' do
         (PokerAction::LEGAL_ACPC_CHARACTERS - PokerAction::MODIFIABLE_ACTIONS.values).each do |unmodifiable_action|
            arbitrary_modifier = 9001
            @mock_action.stubs(:to_acpc).returns(unmodifiable_action + arbitrary_modifier.to_s)
            expect{ActionSender.send_action(@connection, @match_state, @mock_action)}.to raise_exception(ActionSender::IllegalActionFormat)
         end
      end
      it 'can send all legal modifiable actions through the provided connection with a modifier' do
         PokerAction::MODIFIABLE_ACTIONS.values.each do |action|
            arbitrary_modifier = 9001
            action_string = action + arbitrary_modifier.to_s
            @mock_action.stubs(:to_acpc).returns(action_string)
            action_that_should_be_sent = @match_state.to_s + ":#{action_string}"
            @connection.expects(:write).once.with(action_that_should_be_sent)
            
            ActionSender.send_action @connection, @match_state, @mock_action
         end
      end
      it 'works for all test data examples' do
         DealerData::DATA.each do |num_players, data_by_num_players|
            data_by_num_players.each do |type, data_by_type|
               turns = data_by_type[:actions]
               
               # Sample the dealer match string and action data
               number_of_tests = 100
               number_of_tests.times do |i|
                  turn = if !turns[i * (turns.length/number_of_tests)][:from_players].empty?
                     turns[i * (turns.length/number_of_tests)]
                  elsif !turns[i * (turns.length/number_of_tests) + 1][:from_players].empty?
                     turns[i * (turns.length/number_of_tests) + 1]
                  else
                     turns[i * (turns.length/number_of_tests) - 1]
                  end
                  
                  from_player_message = turn[:from_players]
                  seat_taking_action = from_player_message.keys.first
                  
                  action = from_player_message[seat_taking_action]
                  @mock_action.stubs(:to_acpc).returns(action)
                  
                  @match_state = MatchStateString.parse turn[:to_players][seat_taking_action]
                  action_that_should_be_sent = "#{@match_state}:#{action}"
                  
                  @connection.expects(:write).once.with(action_that_should_be_sent)
                     
                  ActionSender.send_action @connection, @match_state, @mock_action
               end
            end
         end
      end
   end
end
