
require File.expand_path('../../support/spec_helper', __FILE__)

# System
require 'socket'

# Local modules
require File.expand_path('../../../lib/acpc_poker_basic_proxy/acpc_poker_basic_proxy_defs', __FILE__)

# Local classes
require File.expand_path('../../../lib/acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator', __FILE__)

describe AcpcDealerCommunicator do
   include AcpcPokerBasicProxyDefs
   
   before(:each) do
      start_test_connection 0
      @client_connection.gets.chomp.should eq("#{AcpcPokerBasicProxyDefs::VERSION_LABEL}:#{AcpcPokerBasicProxyDefs::VERSION_NUMBERS[:major]}.#{AcpcPokerBasicProxyDefs::VERSION_NUMBERS[:minor]}.#{AcpcPokerBasicProxyDefs::VERSION_NUMBERS[:revision]}")
      
      @match_state = 'MATCHSTATE:0:0::5d5c'
   end
  
   after(:each) do
      @patient.close
      @client_connection.close
   end
   
   describe "#ready_to_read?" do
      it 'lets the caller know that there is not new input from the dealer' do
         @patient.ready_to_read?.should be false
      end
   
      it 'lets the caller know that there is new input from the dealer' do
         @client_connection.puts "New input"
         @patient.ready_to_read?.should be true
      end
   end
   
   describe "#ready_to_write?" do
      it 'lets the caller know if the dealer is ready to receive data' do
         @patient.ready_to_write?.should be true
      end
   end
   
   describe "#write" do
      it "properly sends actions to the dealer" do
         action = @match_state + ':c'
         @patient.write action
         
         @client_connection.gets.chomp.should eq(action)
      end
   end
   
   describe "#gets" do
      it "properly receives matchstate strings from the dealer" do
         @client_connection.puts @match_state
         @patient.gets.should eq(@match_state)
      end
   end
   
   def start_test_connection(port)
      fake_dealer = TCPServer.open(port)
      @patient = AcpcDealerCommunicator.new fake_dealer.addr[1], 'localhost', 0
      
      @client_connection = fake_dealer.accept
   end
end
