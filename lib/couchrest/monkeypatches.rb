# Monkey patch for faster net/http io
if RUBY_VERSION.to_f < 1.9
  require 'timeout'

  BUFSIZE = Net::BufferedIO::BUFSIZE || 65536

  class Net::BufferedIO #:nodoc:
    alias :old_rbuf_fill :rbuf_fill
    def rbuf_fill
      if @io.respond_to?(:read_nonblock)
        begin
          @rbuf << @io.read_nonblock(BUFSIZE)
        rescue Errno::EWOULDBLOCK, Errno::EAGAIN
          retry unless @read_timeout
          retry if IO.select([@io], nil, nil, @read_timeout)
          raise Timeout::Error, "IO timeout"
        end
      else
        timeout(@read_timeout) do
          @rbuf << @io.sysread(BUFSIZE)
        end
      end
    end
  end
end
