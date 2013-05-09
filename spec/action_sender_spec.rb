
require_relative 'support/spec_helper'

require 'acpc_poker_types/acpc_dealer_data/poker_match_data'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/match_state'
require 'acpc_dealer'

require 'acpc_poker_basic_proxy/communication_logic/action_sender'

include AcpcPokerBasicProxy::CommunicationLogic
include AcpcPokerTypes

describe ActionSender do
  before(:each) do
    @connection = MiniTest::Mock.new
    @match_state = AcpcDealerData::PokerMatchData.parse_files(
      match_logs[0].actions_file_path,
      match_logs[0].results_file_path,
      match_logs[0].player_names,
      AcpcDealer::DEALER_DIRECTORY,
      1
    ).data[0].data[0].action_message.state
  end

  describe "#send_action" do
    it 'does not send an illegal action and raises an exception' do
      -> do
        ActionSender.send_action(@connection, @match_state, 'illegal action format')
      end.must_raise ActionSender::IllegalActionFormat
    end
    it 'raises an exception if the given match state does not have the proper format' do
      -> do
        ActionSender.send_action(@connection, 'illegal match state format', PokerAction::CALL)
      end.must_raise MatchState::IncompleteMatchState
    end
    it 'can send all legal actions through the provided connection without a modifier' do
      PokerAction::ACTIONS.each do |action|
        action_that_should_be_sent = @match_state.to_s + ":#{action}"
        @connection.expect :write, nil, [action_that_should_be_sent]

        ActionSender.send_action @connection, @match_state, action
      end
    end
    it 'does not send legal unmodifiable actions that have a modifier and raises an exception' do
      (PokerAction::ACTIONS - PokerAction::MODIFIABLE_ACTIONS).each do |unmodifiable_action|
        -> do
          ActionSender.send_action(@connection, @match_state, unmodifiable_action + 9001.to_s)
        end.must_raise ActionSender::IllegalActionFormat
      end
    end
    it 'can send all legal modifiable actions through the provided connection with a modifier' do
      PokerAction::MODIFIABLE_ACTIONS.each do |action|
        arbitrary_modifier = 9001
        action_string = action + arbitrary_modifier.to_s
        action_that_should_be_sent = @match_state.to_s + ":#{action_string}"
        @connection.expect :write, nil, [action_that_should_be_sent]

        ActionSender.send_action @connection, @match_state, action_string
      end
    end
    it 'works for all test data examples' do
      match_logs.each do |log_description|
        match = AcpcDealerData::PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          60
        )
        match.for_every_seat! do |seat|
          match.for_every_hand! do
            match.for_every_turn! do
              next unless match.current_hand.next_action

              from_player_message = match.current_hand.next_action.state
              seat_taking_action = match.current_hand.next_action.seat
              action = match.current_hand.next_action.action

              action_that_should_be_sent = "#{from_player_message.to_s}:#{action.to_acpc}"

              @connection.expect :write, nil, [action_that_should_be_sent]

              ActionSender.send_action @connection, from_player_message, action
            end
          end
        end
      end
    end
  end
end
