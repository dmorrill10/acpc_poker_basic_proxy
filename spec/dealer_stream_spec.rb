
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
      end_test_connection!
    end
    it "fails if the port doesn't correspond to a running server" do
      fake_dealer = TCPServer.open(0)
      port = fake_dealer.addr[1]
      fake_dealer.close
      -> { DealerStream.new(port) }.must_raise DealerStream::UnableToConnectToDealer
    end
  end
  let(:port) { 0 }
  let(:fake_dealer) { TCPServer.open(port) }
  let(:client_connection) { fake_dealer.accept }
  let(:patient) do
    DealerStream.new(
      fake_dealer.addr[1],
      'localhost'
    )
  end
  let(:match_state) { 'MATCHSTATE:0:0::5d5c' }

  describe "#ready_to_read?" do
    it 'lets the caller know that there is new input from the dealer' do
      connect_successfully!
      client_connection.puts "New input"
      patient.ready_to_read?.must_equal true
    end
  end
  describe "#ready_to_write?" do
    it 'lets the caller know if the dealer is ready to receive data' do
      connect_successfully!
      patient.ready_to_write?.must_equal true
    end
  end
  describe "#write" do
    it "properly sends actions to the dealer" do
      connect_successfully!
      action = match_state + ':c'
      patient.write action

      client_connection.gets.chomp.must_equal(action)
    end
  end
  describe "#gets" do
    it "properly receives matchstate strings from the dealer" do
      connect_successfully!
      client_connection.puts match_state
      patient.gets.must_equal(match_state)
    end
  end

  def end_test_connection!
    patient.close if !patient.closed?
    client_connection.close if !client_connection.closed?
  end

  def connect_successfully!
    patient
    client_connection.gets.chomp.must_equal(
      "#{DealerStream::VERSION_LABEL}:#{DealerStream::VERSION_NUMBERS[:major]}.#{DealerStream::VERSION_NUMBERS[:minor]}.#{DealerStream::VERSION_NUMBERS[:revision]}"
    )
  end
end
