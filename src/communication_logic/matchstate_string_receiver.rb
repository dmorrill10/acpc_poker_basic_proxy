
# @todo Only want MatchstateString and AcpcPokerTypesDefs here, is there a way to select this?
require 'acpc_poker_types'

# Receives and parses matchstate strings.
class MatchstateStringReceiver
   include AcpcPokerTypesDefs
   
   # Receives a matchstate string from the given +connection+.
   # @param [#gets] connection The connection from which a matchstate string should be received.
   # @return [MatchstateString] The matchstate string that was received from the +connection+.
   def self.receive_matchstate_string(connection)
      MatchstateString.new(connection.gets)
   end
end
