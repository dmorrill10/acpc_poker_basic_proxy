
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/poker_action'
require 'acpc_dealer_data'
require 'acpc_dealer'

require File.expand_path('../../lib/acpc_poker_basic_proxy/basic_proxy', __FILE__)

describe BasicProxy do
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
            action = if match.current_hand.next_action
              match.current_hand.next_action.action
            else
              nil
            end
            match_state = match.current_hand.current_match_state

            @dealer_communicator.stubs(:gets).returns(match_state.to_s)

            @patient.receive_match_state!.should == match_state

            if action && match_state == match.current_hand.next_action.state && match.current_hand.next_action.seat == seat

              ActionSender.expects(:send_action).once.with(@dealer_communicator, match_state.to_s, action)

              @patient.send_action(action)
            end
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
