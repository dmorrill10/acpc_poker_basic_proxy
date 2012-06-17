
require 'acpc_poker_types/match_state'

# Receives match state strings.
class MatchStateReceiver

  # Receives a match state string from the given +connection+.
  # @param [#gets] connection The connection from which a match state string should be received.
  # @return [MatchState] The match state string that was received from the +connection+ or +nil+ if none could be received.
  def self.receive_match_state(connection)
    raw_match_state = connection.gets
    MatchState.parse raw_match_state
  end
end
