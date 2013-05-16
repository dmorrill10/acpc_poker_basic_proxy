
require_relative 'support/spec_helper'

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/acpc_dealer_data/poker_match_data'
require 'acpc_dealer'

require 'acpc_poker_basic_proxy/basic_proxy'

include AcpcPokerBasicProxy
include AcpcPokerTypes
include AcpcDealerData

describe BasicProxy do
  before(:each) do
    port_number = 9001
    host_name = 'localhost'
    millisecond_response_timeout = 0
    delaer_info = AcpcDealer::ConnectionInformation.new port_number, host_name, millisecond_response_timeout
    @dealer_communicator = mock 'DealerStream'

    DealerStream.expects(:new).once.with(port_number, host_name, millisecond_response_timeout).returns(@dealer_communicator)

    @patient = BasicProxy.new delaer_info

    @connection = MiniTest::Mock.new
    @match_state = AcpcDealerData::PokerMatchData.parse_files(
      MatchLog.all[0].actions_file_path,
      MatchLog.all[0].results_file_path,
      MatchLog.all[0].player_names,
      AcpcDealer::DEALER_DIRECTORY,
      1
    ).data[0].data[0].action_message.state
  end

  it 'given a sequence of match states and actions, it properly sends and receives them' do
    MatchLog.all.each do |log_description|
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
            action = if match.current_hand.next_action
              match.current_hand.next_action.action
            else
              nil
            end
            match_state = match.current_hand.current_match_state

            @dealer_communicator.stubs(:gets).returns(match_state.to_s)

            @patient.receive_match_state!.must_equal match_state

            if action && match_state == match.current_hand.next_action.state && match.current_hand.next_action.seat == seat

              BasicProxy.expects(:send_action).once.with(@dealer_communicator, match_state.to_s, action)

              @patient.send_action(action)
            end
          end
        end
      end
    end
  end
  describe '#send_action' do
    it 'raises an exception if a match state was not received before an action was sent' do
      -> {@patient.send_action(mock('PokerAction'))}.must_raise BasicProxy::InitialMatchStateNotYetReceived
    end
  end
  describe "#send_action" do
    it 'does not send an illegal action and raises an exception' do
      -> do
        BasicProxy.send_action(@connection, @match_state, 'illegal action format')
      end.must_raise BasicProxy::IllegalActionFormat
    end
    it 'raises an exception if the given match state does not have the proper format' do
      -> do
        BasicProxy.send_action(@connection, 'illegal match state format', PokerAction::CALL)
      end.must_raise MatchState::IncompleteMatchState
    end
    it 'can send all legal actions through the provided connection without a modifier' do
      PokerAction::ACTIONS.each do |action|
        action_that_should_be_sent = @match_state.to_s + ":#{action}"
        @connection.expect :write, nil, [action_that_should_be_sent]

        BasicProxy.send_action @connection, @match_state, action
      end
    end
    it 'does not send legal unmodifiable actions that have a modifier and raises an exception' do
      (PokerAction::ACTIONS - PokerAction::MODIFIABLE_ACTIONS).each do |unmodifiable_action|
        -> do
          BasicProxy.send_action(@connection, @match_state, unmodifiable_action + 9001.to_s)
        end.must_raise BasicProxy::IllegalActionFormat
      end
    end
    it 'can send all legal modifiable actions through the provided connection with a modifier' do
      PokerAction::MODIFIABLE_ACTIONS.each do |action|
        arbitrary_modifier = 9001
        action_string = action + arbitrary_modifier.to_s
        action_that_should_be_sent = @match_state.to_s + ":#{action_string}"
        @connection.expect :write, nil, [action_that_should_be_sent]

        BasicProxy.send_action @connection, @match_state, action_string
      end
    end
    it 'works for all test data examples' do
      MatchLog.all.each do |log_description|
        match = AcpcDealerData::PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          20
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

              BasicProxy.send_action @connection, from_player_message, action
            end
          end
        end
      end
    end
  end
end
