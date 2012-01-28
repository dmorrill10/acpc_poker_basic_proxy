
# Mixin to add methods to IO so that they will also be inherited by TCPSocket.
class IO
   # Checks if the socket is ready to be read from.
   # @param [Integer] timeout_in_seconds Amount of time to wait for the sever to respond, in seconds. Must be positive or +nil+.
   # @return [Boolean] +true+ if the socket is ready to be read from, +false+ otherwise.
   def ready_to_read?(timeout_in_seconds=nil)
      read_array = [self]
      write_array = nil
      error_array = nil

      select read_array, write_array, error_array, timeout_in_seconds
   end
   
   # Checks if the socket is ready to be written to.
   # @param [Integer] timeout_in_seconds Amount of time to wait for the sever to respond, in seconds. Must be positive or +nil+.
   # @return [Boolean] +true+ if the socket is ready to be written to, +false+ otherwise.
   def ready_to_write?(timeout_in_seconds=nil)
      read_array = nil
      write_array = [self]
      error_array = nil
      
      select read_array, write_array, error_array, timeout_in_seconds
   end
   
   private
   
   def select(read_array, write_array=[], error_array=[], timeout_in_seconds=nil)
      IO.select(read_array, write_array, error_array, nil) != nil
      #if timeout_in_seconds
      #   IO.select(read_array, write_array, error_array, timeout_in_seconds) != nil
      #else
      #   IO.select(read_array, write_array, error_array) != nil
      #end
   end
end
