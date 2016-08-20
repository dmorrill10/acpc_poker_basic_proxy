require 'socket'
require 'delegate'

module AcpcPokerBasicProxy
  module IoRefinement
    refine IO do
      # Checks if the socket is ready to be read from.
      # @param [Integer] timeout_in_seconds Amount of time to wait for the sever to respond, in seconds. Must be positive or +nil+.
      # @return [Boolean] +true+ if the socket is ready to be read from, +false+ otherwise.
      def ready_to_read?(timeout_in_seconds=nil)
        read_array = [self]
        write_array = nil
        error_array = nil

        select?(read_array, write_array, error_array, timeout_in_seconds)
      end

      # Checks if the socket is ready to be written to.
      # @param [Integer] timeout_in_seconds Amount of time to wait for the sever to respond, in seconds. Must be positive or +nil+.
      # @return [Boolean] +true+ if the socket is ready to be written to, +false+ otherwise.
      def ready_to_write?(timeout_in_seconds=nil)
        read_array = nil
        write_array = [self]
        error_array = nil

        select?(read_array, write_array, error_array, timeout_in_seconds)
      end

      private

      # @see IO#select
      def select?(read_array, write_array=[], error_array=[], timeout_in_seconds=nil)
        IO.select(read_array, write_array, error_array, timeout_in_seconds) != nil
      end
    end
  end
end
using AcpcPokerBasicProxy::IoRefinement

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# Communication service to the ACPC Dealer.
# It acts solely as an abstraction of the communication protocol and
# implements the main Ruby communication interface through 'gets' and 'puts'
# methods.
module AcpcPokerBasicProxy
  class DealerStream < DelegateClass(TCPSocket)
    exceptions :unable_to_connect_to_dealer, :unable_to_write_to_dealer, :unable_to_get_from_dealer

    # @return [String] The ACPC dealer version label.
    VERSION_LABEL = 'VERSION'

    # @return [Hash] The ACPC dealer version numbers.
    VERSION_NUMBERS = {:major => 2, :minor => 0, :revision => 0}

    # @return [String] Dealer specified string terminator.
    TERMINATION_STRING = "\r\n"

    READY_MESSAGE = '#READY'

    # @param [Integer] port The port on which to connect to the dealer.
    # @param [String] host_name The host on which the dealer is running. Defaults to 'localhost'
    # @raise AcpcDealerConnectionError, UnableToWriteToDealer
    def initialize(port, host_name='localhost')
      @dealer_socket = nil
      begin
        @dealer_socket = TCPSocket.new(host_name, port)
        super @dealer_socket

        send_version_string_to_dealer
      rescue UnableToWriteToDealer
        raise
      rescue Errno::ECONNREFUSED => e
        handle_error UnableToConnectToDealer, "Unable to connect to the dealer on #{host_name} through port #{port}", e
      end
    end

    # Retrieves a string from the dealer.
    #
    # @return [String] A string from the dealer.
    # @raise UnableToGetFromDealer
    def gets
      begin
        string_from_dealer
      rescue => e
        handle_error UnableToGetFromDealer, "Unable to get a string from the dealer", e
      end
    end

    # Sends a given +string+ to the dealer.
    #
    # @param [String] string The string to send.
    # @return (see #send_string_to_dealer)
    # @raise UnableToWriteToDealer
    def write(string)
      begin
        send_string_to_dealer string
      rescue => e
        handle_error UnableToWriteToDealer, "Unable to send the string, \"#{string}\", to the dealer", e
      end
    end

    # @see TCPSocket#ready_to_write?
    def ready_to_write?
      @dealer_socket.ready_to_write?
    end

    # @see TCPSocket#ready_to_read?
    def ready_to_read?
      @dealer_socket.ready_to_read?
    end

    private

    def handle_error(exception, message, context_exception)
      close if @dealer_socket && !closed?
      raise exception.with_context(message, context_exception)
    end

    # @return (see #send_string_to_dealer)
    def send_version_string_to_dealer
      version_string = "#{VERSION_LABEL}:#{VERSION_NUMBERS[:major]}.#{VERSION_NUMBERS[:minor]}.#{VERSION_NUMBERS[:revision]}"
      begin
        send_string_to_dealer version_string
      rescue => e
        handle_error UnableToWriteToDealer, "Unable to send version string, \"#{version_string}\", to the dealer", e
      end
    end

    # @return [Integer] The number of bytes written to the dealer.
    def send_string_to_dealer(string)
      raise unless ready_to_write?
      @dealer_socket.write(string + TERMINATION_STRING)
    end

    def string_from_dealer
      raise unless ready_to_read?
      @dealer_socket.gets.chomp
    end
  end
end
