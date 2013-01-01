
require File.expand_path('../../support/spec_helper', __FILE__)

require 'acpc_dealer'
require 'acpc_dealer_data'

require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/match_state_receiver', __FILE__)
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator', __FILE__)

describe MatchStateReceiver do
  before(:each) do
    @connection = mock 'AcpcDealerCommunicator'
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
              @connection.expects(:gets).once.returns(match.current_hand.current_match_state.to_s)

              MatchStateReceiver.receive_match_state(@connection).should == match.current_hand.current_match_state
            end
          end
        end
      end
    end
  end
end
