module IoUnblock
  class TcpSocket
    extend Forwardable

    def_delegators :@stream, :start, :stop, :callbacks, :write,
      :running?, :connected?, :alive?, :select_delay, :select_delay=
    attr_reader :host, :port

    def initialize host, port, callbacks=nil
      @host = host
      @port = port
      @socket = ::TCPSocket.new host, port
      @stream = Stream.new @socket, callbacks
    end
  end
end
