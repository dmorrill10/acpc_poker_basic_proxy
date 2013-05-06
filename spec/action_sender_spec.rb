
require File.expand_path('../../support/spec_helper', __FILE__)

require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/match_state'
require 'acpc_dealer'
require 'acpc_dealer_data'

require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/action_sender', __FILE__)

describe ActionSender do
  before(:each) do
    @connection = mock 'AcpcDealerCommunicator'
    @mock_action = mock 'PokerAction'
    @match_state = PokerMatchData.parse_files(
      match_logs[0].actions_file_path,
      match_logs[0].results_file_path,
      match_logs[0].player_names,
      AcpcDealer::DEALER_DIRECTORY,
      1
    ).data[0].data[0].action_message.state
  end

  describe "#send_action" do
    it 'does not send an illegal action and raises an exception' do
      @mock_action.stubs(:to_acpc).returns('illegal action format')
      expect do
        ActionSender.send_action(@connection, @match_state, @mock_action)
      end.to raise_exception(ActionSender::IllegalActionFormat)
    end
    it 'raises an exception if the given match state does not have the proper format' do
      @match_state = 'illegal match state format'
      @mock_action.stubs(:to_acpc).returns('c')
      expect do
        ActionSender.send_action(@connection, @match_state, @mock_action)
      end.to raise_exception(MatchState::IncompleteMatchState)
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
        expect do 
          ActionSender.send_action(@connection, @match_state, @mock_action)
        end.to raise_exception(ActionSender::IllegalActionFormat)
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
      match_logs.each do |log_description|
        match = PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          10
        )
        match.for_every_seat! do |seat|
          match.for_every_hand! do
            match.for_every_turn! do
              next unless match.current_hand.next_action
              
              from_player_message = match.current_hand.next_action.state
              seat_taking_action = match.current_hand.next_action.seat
              action = match.current_hand.next_action.action

              action_that_should_be_sent = "#{from_player_message.to_s}:#{action.to_acpc}"

              @connection.expects(:write).once.with(action_that_should_be_sent)

              ActionSender.send_action @connection, from_player_message, action
            end
          end
        end
      end
    end
  end
end
