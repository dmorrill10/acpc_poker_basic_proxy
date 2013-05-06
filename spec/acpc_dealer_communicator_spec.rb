
require_relative 'support/spec_helper'

require 'socket'

require 'acpc_poker_basic_proxy/communication_logic/acpc_dealer_communicator'

describe AcpcPokerBasicProxy::CommunicationLogic::AcpcDealerCommunicator do

  before do
    start_test_connection 0
    @client_connection.gets.chomp.must_equal(
      "#{AcpcPokerBasicProxy::CommunicationLogic::AcpcDealerCommunicator::VERSION_LABEL}:#{AcpcPokerBasicProxy::CommunicationLogic::AcpcDealerCommunicator::VERSION_NUMBERS[:major]}.#{AcpcPokerBasicProxy::CommunicationLogic::AcpcDealerCommunicator::VERSION_NUMBERS[:minor]}.#{AcpcPokerBasicProxy::CommunicationLogic::AcpcDealerCommunicator::VERSION_NUMBERS[:revision]}"
    )

    @match_state = 'MATCHSTATE:0:0::5d5c'
  end

  after do
    @patient.close
    @client_connection.close
  end

  describe "#ready_to_read?" do
    it 'lets the caller know that there is not new input from the dealer' do
      @patient.ready_to_read?.must_equal false
    end

    it 'lets the caller know that there is new input from the dealer' do
      @client_connection.puts "New input"
      @patient.ready_to_read?.must_equal true
    end
  end

  describe "#ready_to_write?" do
    it 'lets the caller know if the dealer is ready to receive data' do
      @patient.ready_to_write?.must_equal true
    end
  end

  describe "#write" do
    it "properly sends actions to the dealer" do
      action = @match_state + ':c'
      @patient.write action

      @client_connection.gets.chomp.must_equal(action)
    end
  end

  describe "#gets" do
    it "properly receives matchstate strings from the dealer" do
      @client_connection.puts @match_state
      @patient.gets.must_equal(@match_state)
    end
  end

  def start_test_connection(port)
    fake_dealer = TCPServer.open(port)
    @patient = AcpcPokerBasicProxy::CommunicationLogic::AcpcDealerCommunicator.new(
      fake_dealer.addr[1],
      'localhost',
      0
    )

    @client_connection = fake_dealer.accept
  end
end
