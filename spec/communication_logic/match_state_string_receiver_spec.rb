
require File.expand_path('../../support/spec_helper', __FILE__)

# Local modules
require File.expand_path('../../support/model_test_helper', __FILE__)

# Local classes
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/match_state_string_receiver', __FILE__)
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator', __FILE__)

describe MatchStateStringReceiver do
   include ModelTestHelper
   
   before(:each) do
      @connection = mock 'AcpcDealerCommunicator'
      @matchstate = create_initial_match_state.shift
   end
   
   describe "#receive_matchstate_string" do
      it 'receives matchstate strings properly' do
         raw_matchstate_string = @matchstate.to_s
         @connection.expects(:gets).once.returns(raw_matchstate_string)
         MatchStateString.stubs(:new).returns(@matchstate)
         
         MatchStateStringReceiver.receive_matchstate_string(@connection).should == @matchstate
      end
   end
end
