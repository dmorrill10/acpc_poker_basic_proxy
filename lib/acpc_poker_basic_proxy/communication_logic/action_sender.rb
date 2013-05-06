
require 'dmorrill10-utils/class'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/match_state'

# Sends poker actions according to the ACPC protocol.
module AcpcPokerBasicProxy
  module CommunicationLogic
    class ActionSender
      exceptions :illegal_action_format

      CONCATENATED_MODIFIABLE_ACTIONS = AcpcPokerTypes::PokerAction::MODIFIABLE_ACTIONS.to_a.join

      # Sends the given +action+ to through the given +connection+ in the ACPC
      # format.
      # @param [#write, #ready_to_write?] connection The connection through which the +action+
      #  should be sent.
      # @param [#to_s] match_state The current match state.
      # @param [#to_s] action The action to be sent through the +connection+.
      # @return [Integer] The number of bytes written.
      # @raise (see #validate_match_state)
      # @raise (see #validate_action)
      def self.send_action(connection, match_state, action)
        validate_action action

        full_action = "#{AcpcPokerTypes::MatchState.parse(match_state.to_s)}:#{action.to_s}"
        connection.write full_action
      end

      private

      # @raise IllegalActionFormat
      def self.validate_action(action)
        raise IllegalActionFormat unless self.valid_action?(action)
      end

      def self.valid_action?(action)
        action.to_s.match(/^[#{AcpcPokerTypes::PokerAction::CONCATONATED_ACTIONS}]$/) ||
        action.to_s.match(/^[#{CONCATENATED_MODIFIABLE_ACTIONS}]\d+$/)
      end
    end
  end
end