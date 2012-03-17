
# Gems
require 'acpc_poker_types'

# Assortment of methods to support model tests
module ModelTestHelper
   
   # Initialization methods ---------------------------------------------------
   def create_initial_match_state(number_of_players = 2)
      user_position = 1;
      hand_number = 0
      hole_card_hand = arbitrary_hole_card_hand
      initial_match_state = mock('MatchstateString')
      initial_match_state.stubs(:position_relative_to_dealer).returns(user_position)
      initial_match_state.stubs(:hand_number).returns(hand_number)
      initial_match_state.stubs(:list_of_board_cards).returns([])
      initial_match_state.stubs(:list_of_betting_actions).returns([])
      initial_match_state.stubs(:users_hole_cards).returns(hole_card_hand)      
      initial_match_state.stubs(:list_of_opponents_hole_cards).returns([])
      initial_match_state.stubs(:list_of_hole_card_hands).returns(list_of_hole_card_hands(user_position, hole_card_hand, number_of_players))
      initial_match_state.stubs(:last_action).returns(nil)
      initial_match_state.stubs(:round).returns(0)
      initial_match_state.stubs(:number_of_actions_in_current_round).returns(0)
      
      raw_match_state =  AcpcPokerTypesDefs::MATCH_STATE_LABEL + ":#{user_position}:#{hand_number}::" + hole_card_hand
      initial_match_state.stubs(:to_s).returns(raw_match_state)
      
      [initial_match_state, user_position]
   end
   
   def list_of_hole_card_hands(user_position, user_hole_card_hand, number_of_players)
      if user_position == number_of_players - 1
         number_of_entries_in_the_list = number_of_players - 1
      else
         number_of_entries_in_the_list = number_of_players - 2
      end
      
      hole_card_sets = []
      number_of_entries_in_the_list.times do |i|
         hole_card_sets << if i == user_position then user_hole_card_hand else '' end
      end
      
      hole_card_sets   
   end
   
   # Construct an arbitrary hole card hand.
   #
   # @return [Mock Hand] An arbitrary hole card hand.
   def arbitrary_hole_card_hand
      hand = mock('Hand')
      hand_as_string = AcpcPokerTypesDefs::CARD_RANKS[:two] +
      AcpcPokerTypesDefs::CARD_SUITS[:spades][:acpc_character] +
      AcpcPokerTypesDefs::CARD_RANKS[:three] +
      AcpcPokerTypesDefs::CARD_SUITS[:hearts][:acpc_character]
      hand.stubs(:to_str).returns(hand_as_string)
      hand.stubs(:to_s).returns(hand_as_string)
      hand
   end
end