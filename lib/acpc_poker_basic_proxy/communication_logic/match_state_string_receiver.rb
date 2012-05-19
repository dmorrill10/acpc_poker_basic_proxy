
require 'acpc_poker_types/types/match_state_string'

# Receives match state strings.
class MatchStateStringReceiver
   
   # Receives a match state string from the given +connection+.
   # @param [#gets] connection The connection from which a matchstate string should be received.
   # @return [MatchStateString] The match state string that was received from the +connection+ or +nil+ if none could be received.
   def self.receive_matchstate_string(connection)
      raw_match_state_string = connection.gets
      MatchStateString.new(raw_match_state_string)
   end
end
