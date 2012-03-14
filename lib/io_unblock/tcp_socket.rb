module IoUnblock
  class TcpSocket
    extend Forwardable

    def_delegators :@stream, :start, :stop, :callbacks,
      :running?, :connected?, :select_delay, :select_delay=
    attr_reader :host, :port

    def initialize host, port, callbacks=nil
      @host = host
      @port = port
      @socket = ::TCPSocket.new host, port
      @stream = Stream.new @socket, callbacks
    end
  end
end
