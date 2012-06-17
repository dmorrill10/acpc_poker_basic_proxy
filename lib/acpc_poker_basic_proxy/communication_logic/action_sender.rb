
require 'dmorrill10-utils/class'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/rank'
require 'acpc_poker_types/suit'

# Sends poker actions according to the ACPC protocol.
class ActionSender

  exceptions :illegal_action_format

  # Sends the given +action+ to through the given +connection+ in the ACPC
  # format.
  # @param [#write, #ready_to_write?] connection The connection through which the +action+
  #  should be sent.
  # @param [#to_s] match_state The current match state.
  # @param [#to_acpc] action The action to be sent through the +connection+.
  # @return [Integer] The number of bytes written.
  # @raise (see #validate_match_state)
  # @raise (see #validate_action)
  def self.send_action(connection, match_state, action)
    validate_action action

    full_action = "#{MatchState.parse(match_state.to_s)}:#{action.to_acpc}"
    connection.write full_action
  end

  private

  # @raise IllegalActionFormat
  def self.validate_action(action)
    raise IllegalActionFormat unless self.valid_action?(action)
  end

  def self.valid_action?(action)
    all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join('')
    modifiable_actions = PokerAction::MODIFIABLE_ACTIONS.values.to_a.join('')

    action.to_acpc.match(/^[#{all_actions}]$/) || action.to_acpc.match(/^[#{modifiable_actions}]\d+$/)
  end
end
