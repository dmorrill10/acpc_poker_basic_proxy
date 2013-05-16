
require_relative 'support/spec_helper'

require 'socket'

require 'acpc_poker_basic_proxy/dealer_stream'

include AcpcPokerBasicProxy

describe DealerStream do
  after do
    end_test_connection!
  end
  describe '#new' do
    it 'works properly' do
      start_test_connection!
      end_test_connection!
    end
    it "fails if the port doesn't correspond to a running server" do
      fake_dealer = TCPServer.open(0)
      port = fake_dealer.addr[1]
      fake_dealer.close
      -> { DealerStream.new(port) }.must_raise DealerStream::UnableToConnectToDealer
    end
  end
  describe "#ready_to_read?" do
    it 'lets the caller know that there is not new input from the dealer' do
      connect_successfully!
      @patient.ready_to_read?.must_equal false
    end
    it 'lets the caller know that there is new input from the dealer' do
      connect_successfully!
      @client_connection.puts "New input"
      @patient.ready_to_read?.must_equal true
    end
  end
  describe "#ready_to_write?" do
    it 'lets the caller know if the dealer is ready to receive data' do
      connect_successfully!
      @patient.ready_to_write?.must_equal true
    end
  end
  describe "#write" do
    it "properly sends actions to the dealer" do
      connect_successfully!
      action = @match_state + ':c'
      @patient.write action

      @client_connection.gets.chomp.must_equal(action)
    end
  end
  describe "#gets" do
    it "properly receives matchstate strings from the dealer" do
      connect_successfully!
      @client_connection.puts @match_state
      @patient.gets.must_equal(@match_state)
    end
    it 'disconnects if the timeout is reached' do
      [0, 100].each do |t|
        start_test_connection! t
        -> { @patient.gets }.must_raise DealerStream::UnableToGetFromDealer
      end
    end
  end

  def end_test_connection!
    @patient.close if @patient && !@patient.closed?
    @client_connection.close if @client_connection && !@client_connection.closed?
  end

  def start_test_connection!(millisecond_response_timeout = 0, port = 0)
    fake_dealer = TCPServer.open(port)
    @patient = DealerStream.new(
      fake_dealer.addr[1],
      'localhost',
      millisecond_response_timeout
    )
    @client_connection = fake_dealer.accept
  end

  def connect_successfully!
    start_test_connection!
    @client_connection.gets.chomp.must_equal(
      "#{DealerStream::VERSION_LABEL}:#{DealerStream::VERSION_NUMBERS[:major]}.#{DealerStream::VERSION_NUMBERS[:minor]}.#{DealerStream::VERSION_NUMBERS[:revision]}"
    )

    @match_state = 'MATCHSTATE:0:0::5d5c'
  end
end
