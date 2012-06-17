
require File.expand_path('../communication_logic/acpc_dealer_communicator', __FILE__)
require File.expand_path('../communication_logic/acpc_dealer_information', __FILE__)
require File.expand_path('../communication_logic/action_sender', __FILE__)
require File.expand_path('../communication_logic/match_state_receiver', __FILE__)

# A bot that connects to a dealer as a proxy.
class BasicProxy
  exceptions :initial_match_state_not_yet_received

  # @param [AcpcDealerInformation] dealer_information Information about the dealer to which this bot should connect.
  def initialize(dealer_information)
    @dealer_communicator = AcpcDealerCommunicator.new dealer_information.port_number, dealer_information.host_name, dealer_information.millisecond_response_timeout
  end

  # @param [PokerAction] action The action to be sent.
  # @return (see ActionSender#send_action)
  # @raise InitialMatchStateNotYetReceived
  # @raise (see ActionSender#send_action)
  def send_action(action)
    raise InitialMatchStateNotYetReceived unless @match_state
    ActionSender.send_action @dealer_communicator, @match_state, action
  end

  # @see MatchStateReceiver#receive_match_state
  def receive_match_state!
    @match_state = MatchStateReceiver.receive_match_state @dealer_communicator
  end
end
