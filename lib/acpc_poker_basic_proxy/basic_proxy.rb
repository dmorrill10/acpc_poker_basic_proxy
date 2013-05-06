
require 'acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator'
require 'acpc_poker_basic_proxy/communication_logic/acpc_dealer_information'
require 'acpc_poker_basic_proxy/communication_logic/action_sender'
require 'acpc_poker_basic_proxy/communication_logic/match_state_receiver'

# A bot that connects to a dealer as a proxy.
module AcpcPokerBasicProxy
  class BasicProxy
    exceptions :initial_match_state_not_yet_received

    # @param [AcpcDealerInformation] dealer_information Information about the dealer to which this bot should connect.
    def initialize(dealer_information)
      @dealer_communicator = CommunicationLogic::AcpcDealerCommunicator.new dealer_information.port_number, dealer_information.host_name, dealer_information.millisecond_response_timeout
    end

    # @param [PokerAction] action The action to be sent.
    # @return (see ActionSender#send_action)
    # @raise InitialMatchStateNotYetReceived
    # @raise (see ActionSender#send_action)
    def send_action(action)
      raise InitialMatchStateNotYetReceived unless @match_state
      CommunicationLogic::ActionSender.send_action @dealer_communicator, @match_state, action
    end

    # @see MatchStateReceiver#receive_match_state
    def receive_match_state!
      @match_state = CommunicationLogic::MatchStateReceiver.receive_match_state @dealer_communicator
    end
  end
end