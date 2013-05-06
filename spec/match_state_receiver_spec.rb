
require_relative 'support/spec_helper'

require 'acpc_dealer'
require 'acpc_poker_types'

require 'acpc_poker_basic_proxy/communication_logic/match_state_receiver'
require 'acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator'

describe AcpcPokerBasicProxy::CommunicationLogic::MatchStateReceiver do
  before(:each) do
    @connection = MiniTest::Mock.new
  end

  describe "#receive_matchstate_string" do
    it 'receives matchstate strings properly' do
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
              @connection.expect(:gets, match.current_hand.current_match_state.to_s).once

              AcpcPokerBasicProxy::MatchStateReceiver.receive_match_state(@connection).must_equal match.current_hand.current_match_state
            end
          end
        end
      end
    end
  end
end
