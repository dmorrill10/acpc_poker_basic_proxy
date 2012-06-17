
require 'socket'
require 'dmorrill10-utils/class'

require File.expand_path('../../mixins/socket_with_ready_methods', __FILE__)

# Communication service to the ACPC Dealer.
# It acts solely as an abstraction of the communication protocol and
# implements the main Ruby communication interface through 'gets' and 'puts'
# methods.
class AcpcDealerCommunicator
  exceptions :acpc_dealer_connection_error, :put_to_acpc_dealer_error, :get_from_acpc_dealer_error

  # @return [String] The ACPC dealer version label.
  VERSION_LABEL = 'VERSION'
  
  # @return [Hash] The ACPC dealer version numbers.
  VERSION_NUMBERS = {:major => 2, :minor => 0, :revision => 0}
   
  # @return [String] Dealer specified string terminator.
  TERMINATION_STRING = "\r\n"

  # @param [Integer] port The port on which to connect to the dealer.
  # @param [String] host_name The host on which the dealer is running.
  # @param [Integer] millisecond_response_timeout The dealer's response timeout, in milleseconds.
  # @raise AcpcDealerConnectionError, PutToAcpcDealerError
  def initialize(port, host_name='localhost', millisecond_response_timeout=nil)
    begin
      @dealer_socket = TCPSocket.new(host_name, port)
      @response_timeout_in_seconds = if millisecond_response_timeout
        millisecond_response_timeout/(10**3)
      else
        nil
      end
      send_version_string_to_dealer
    rescue PutToAcpcDealerError
      raise
    rescue
      handle_error AcpcDealerConnectionError, "Unable to connect to the dealer on #{host_name} through port #{port}: #{$?}"
    end
  end

  # Closes the connection to the dealer.
  def close
    @dealer_socket.close if @dealer_socket
  end

  # Retrieves a string from the dealer.
  #
  # @return [String] A string from the dealer.
  # @raise GetFromAcpcDealerError
  def gets
    begin
      raw_match_state = string_from_dealer
    rescue
      handle_error GetFromAcpcDealerError, "Unable to get a string from the dealer: #{$?}"
    end
    raw_match_state
  end

  # Sends a given +string+ to the dealer.
  #
  # @param [String] string The string to send.
  # @return (see #send_string_to_dealer)
  # @raise WriteToAcpcDealerError
  def write(string)
    begin
      bytes_written = send_string_to_dealer string
    rescue
      handle_error WriteToAcpcDealerError, "Unable to send the string, \"#{string}\", to the dealer: #{$?}."
    end
    bytes_written
  end

  # @see TCPSocket#ready_to_write?
  def ready_to_write?
    @dealer_socket.ready_to_write? @response_timeout_in_seconds
  end

  # @see TCPSocket#ready_to_read?
  def ready_to_read?
    @dealer_socket.ready_to_read? @response_timeout_in_seconds
  end

  private

  def handle_error(exception, message)
    close
    raise exception, message
  end

  # @return (see #send_string_to_dealer)
  def send_version_string_to_dealer
    version_string = "#{VERSION_LABEL}:#{VERSION_NUMBERS[:major]}.#{VERSION_NUMBERS[:minor]}.#{VERSION_NUMBERS[:revision]}"
    begin
      bytes_written = send_string_to_dealer version_string
    rescue
      handle_error PutToAcpcDealerError, "Unable to send version string, \"#{version_string}\", to the dealer"
    end
    bytes_written
  end

  # @return [Integer] The number of bytes written to the dealer.
  def send_string_to_dealer(string)
    raise unless ready_to_write?
    begin
      bytes_written = @dealer_socket.write(string + TERMINATION_STRING)
    rescue
      raise
    end
    bytes_written
  end

  def string_from_dealer
    raise unless ready_to_read?
    begin
      string = @dealer_socket.gets.chomp
    rescue
      raise
    end
    string
  end
end
