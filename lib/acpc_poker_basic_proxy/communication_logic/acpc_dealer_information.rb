
# Information about a dealer instance.
class AcpcDealerInformation
  # @return [String] The host name of the dealer associated with this table.
  attr_reader :host_name

  # @return [Integer] The port number of the dealer associated with this table.
  attr_reader :port_number

  # @return [Integer] The dealer's response timeout.
  attr_reader :millisecond_response_timeout

  def initialize(host_name, port_number, millisecond_response_timeout=nil)
    @host_name = host_name
    @port_number = port_number
    @millisecond_response_timeout = millisecond_response_timeout
  end
end
