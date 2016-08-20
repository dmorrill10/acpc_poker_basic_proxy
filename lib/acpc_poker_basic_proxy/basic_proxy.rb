require 'acpc_dealer'
require 'acpc_poker_types'

require 'acpc_poker_basic_proxy/dealer_stream'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# A bot that connects to a dealer as a proxy.
module AcpcPokerBasicProxy
  class BasicProxy
    exceptions :initial_match_state_not_yet_received, :illegal_action_format

    CONCATENATED_MODIFIABLE_ACTIONS = (
      AcpcPokerTypes::PokerAction::MODIFIABLE_ACTIONS.to_a.join
    )

    # Sends the given +action+ to through the given +connection+ in the ACPC
    # format.
    # @param [#write, #ready_to_write?] connection The connection through
    #   which the +action+ should send.
    # @param [#to_s] match_state The current match state.
    # @param [#to_s] action The action to send through the +connection+.
    # @return [Integer] The number of bytes written.
    # @raise (see #validate_match_state)
    # @raise (see #validate_action)
    def self.send_action(connection, match_state, action)
      validate_action action

      full_action = (
        "#{AcpcPokerTypes::MatchState.parse(match_state.to_s)}:#{action.to_s}"
      )
      connection.write full_action
    end

    # Sends a comment the given +connection+.
    # @param [#write, #ready_to_write?] connection The connection through
    #   which the +comment+ should send.
    # @param [#to_s] comment The comment to send through the +connection+.
    # @return [Integer] The number of bytes written.
    def self.send_comment(connection, comment)
      connection.write "##{comment}"
    end

    # Sends a ready message to the given +connection+.
    # @param [#write, #ready_to_write?] connection The connection through
    #   which the message should send.
    # @return [Integer] The number of bytes written.
    def self.send_ready(connection)
      connection.write DealerStream::READY_MESSAGE
    end

    # @raise IllegalActionFormat
    def self.validate_action(action)
      raise IllegalActionFormat unless self.valid_action?(action)
    end

    def self.valid_action?(action)
      action.to_s.match(/^[#{AcpcPokerTypes::PokerAction::CONCATONATED_ACTIONS}]$/) ||
      action.to_s.match(/^[#{CONCATENATED_MODIFIABLE_ACTIONS}]\d+$/)
    end

    # @param [AcpcDealer::ConnectionInformation] dealer_information Information about the dealer to which this bot should connect.
    def initialize(dealer_information)
      @dealer_communicator = DealerStream.new(
        dealer_information.port_number,
        dealer_information.host_name
      )
      @match_state = nil
    end

    # @param [PokerAction] action The action to send.
    # @return (see BasicProxy#send_action)
    # @raise InitialMatchStateNotYetReceived
    # @raise (see BasicProxy#send_action)
    def send_action(action)
      raise InitialMatchStateNotYetReceived unless @match_state
      BasicProxy.send_action @dealer_communicator, @match_state, action
    end

    # @param [#to_s] comment The comment to send.
    # @return (see BasicProxy#send_comment)
    def send_comment(comment)
      BasicProxy.send_comment @dealer_communicator, comment
    end

    # @return (see BasicProxy#send_ready)
    def send_ready
      BasicProxy.send_ready @dealer_communicator
    end

    # @see MatchStateReceiver#receive_match_state
    def receive_match_state!
      @match_state = AcpcPokerTypes::MatchState.receive @dealer_communicator
    end
  end
end
