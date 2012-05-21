
require 'acpc_poker_types/acpc_poker_types_defs'
require 'acpc_poker_types/mixins/utils'

# Sends poker actions according to the ACPC protocol.
class ActionSender
   include AcpcPokerTypesDefs
   
   exceptions :illegal_action_format, :illegal_match_state_format
   
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
      validate_match_state match_state
      validate_action action
      
      full_action = match_state.to_s + ":#{action.to_acpc}"
      connection.write full_action
   end
   
   private
   
   # @raise IllegalMatchStateFormat
   def self.validate_match_state(match_state)
      raise IllegalMatchStateFormat unless valid_match_state?(match_state)
   end
   
   def self.valid_match_state?(match_state)
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join
      all_ranks = CARD_RANKS.values.join
      all_suits = (CARD_SUITS.values.map { |suit| suit[:acpc_character] }).join
      all_card_tokens = all_ranks + all_suits
      
      match_state.to_s.match(
         /^#{MATCH_STATE_LABEL}:\d+:\d+:[\d#{all_actions}\/]*:[|#{all_card_tokens}]+\/*[\/#{all_card_tokens}]*$/
      )
   end
   
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
