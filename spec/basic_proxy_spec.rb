
require_relative 'support/spec_helper'

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/dealer_data/poker_match_data'
require 'acpc_dealer'

require 'acpc_poker_basic_proxy/basic_proxy'

include AcpcPokerBasicProxy
include AcpcPokerTypes
include DealerData

describe BasicProxy do
  let(:port_number) { 9001 }
  let(:host_name) { 'localhost' }
  let(:millisecond_response_timeout) { 0 }
  let(:delaer_info) do
    AcpcDealer::ConnectionInformation.new port_number, host_name
  end
  let(:dealer_communicator) { MiniTest::Mock.new }

  let(:patient) do
    fussy = ->(port, host) do
      host.must_equal host_name
      port.must_equal port_number
      dealer_communicator
    end
    DealerStream.stub :new, fussy do
      BasicProxy.new delaer_info
    end
  end

  let(:match_state) do
    PokerMatchData.parse_files(
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

            dealer_communicator.stub :gets, match_state.to_s do
              patient.receive_match_state!.must_equal match_state
            end

            if (
              action &&
              match_state == match.current_hand.next_action.state &&
              match.current_hand.next_action.seat == seat
            )
              dealer_communicator.expect :call, nil
              fussy = ->(dealer_communicator_, match_state_, action_) do
                dealer_communicator_.call
                match_state_.must_equal match_state.to_s
                action_.must_equal action
              end
              BasicProxy.stub :send_action, fussy do
                patient.send_action(action)
              end
            end
          end
        end
      end
    end
  end
  describe '::send_comment' do
    it 'works' do
      comment = 'this is a comment'
      dealer_communicator.expect :write, nil, ["##{comment}"]
      BasicProxy.send_comment(dealer_communicator, comment)
    end
  end
  describe '::send_ready' do
    it 'works' do
      dealer_communicator.expect :write, nil, [DealerStream::READY_MESSAGE]
      BasicProxy.send_ready(dealer_communicator)
    end
  end
  describe '#send_comment' do
    it 'works' do
      comment = 'this is a comment'
      dealer_communicator.expect :write, nil, ["##{comment}"]
      patient.send_comment(comment)
    end
  end
  describe '#send_ready' do
    it 'works' do
      dealer_communicator.expect :write, nil, [DealerStream::READY_MESSAGE]
      patient.send_ready
    end
  end
  describe '#send_action' do
    it 'raises an exception if a match state was not received before an action was sent' do
      -> {patient.send_action(MiniTest::Mock.new)}.must_raise(
        BasicProxy::InitialMatchStateNotYetReceived
      )
    end
  end
  describe "::send_action" do
    it 'does not send an illegal action and raises an exception' do
      -> do
        BasicProxy.send_action(dealer_communicator, match_state, 'illegal action format')
      end.must_raise BasicProxy::IllegalActionFormat
    end
    it 'can send all legal actions through the provided dealer_communicator without a modifier' do
      PokerAction::ACTIONS.each do |action|
        action_that_should_be_sent = match_state.to_s + ":#{action}"
        dealer_communicator.expect :write, nil, [action_that_should_be_sent]

        BasicProxy.send_action dealer_communicator, match_state, action
      end
    end
    it 'does not send legal unmodifiable actions that have a modifier and raises an exception' do
      (PokerAction::ACTIONS - PokerAction::MODIFIABLE_ACTIONS).each do |unmodifiable_action|
        -> do
          BasicProxy.send_action(dealer_communicator, match_state, unmodifiable_action + 9001.to_s)
        end.must_raise BasicProxy::IllegalActionFormat
      end
    end
    it 'can send all legal modifiable actions through the provided dealer_communicator with a modifier' do
      PokerAction::MODIFIABLE_ACTIONS.each do |action|
        arbitrary_modifier = 9001
        action_string = action + arbitrary_modifier.to_s
        action_that_should_be_sent = match_state.to_s + ":#{action_string}"
        dealer_communicator.expect :write, nil, [action_that_should_be_sent]

        BasicProxy.send_action dealer_communicator, match_state, action_string
      end
    end
    it 'works for all test data examples' do
      MatchLog.all.each do |log_description|
        match = PokerMatchData.parse_files(
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
              action = match.current_hand.next_action.action

              action_that_should_be_sent = "#{from_player_message.to_s}:#{action.to_acpc}"

              dealer_communicator.expect :write, nil, [action_that_should_be_sent]

              BasicProxy.send_action dealer_communicator, from_player_message, action
            end
          end
        end
      end
    end
  end
end
