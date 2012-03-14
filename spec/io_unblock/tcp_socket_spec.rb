require File.expand_path("../../spec_helper.rb", __FILE__)

describe IoUnblock::TcpSocket do
  include Stubz

  def tcp_socket
    @tcp_socket ||= IoUnblock::TcpSocket.new('host.name', 33, {:call => :back})
  end

  before do
    @socket = MiniTest::Mock.new
    @stream = MiniTest::Mock.new
    stub(::TCPSocket, :new, @socket)
    stub(::IoUnblock::Stream, :new, @stream)
  end

  describe "attribs" do
    it "has a host" do
      tcp_socket.host.must_equal 'host.name'
    end

    it "has a port" do
      tcp_socket.port.must_equal 33
    end
  end

  describe "delegation to the stream" do
    it "delegates start" do
      @stream.expect(:start, nil, [:some, :args])
      tcp_socket.start :some, :args
      @stream.verify
    end

    it "delegates stop" do
      @stream.expect(:stop, nil, ['moar cowbell'])
      tcp_socket.stop 'moar cowbell'
      @stream.verify
    end

    it "delegates callbacks" do
      @stream.expect(:callbacks, {:a => :hash})
      tcp_socket.callbacks.must_equal({:a => :hash})
      @stream.verify
    end

    it "delegates running?" do
      @stream.expect(:running?, :generally_a_bool)
      tcp_socket.running?.must_equal :generally_a_bool
      @stream.verify
    end

    it "delegates connected?" do
      @stream.expect(:connected?, :again_a_bool)
      tcp_socket.connected?.must_equal :again_a_bool
      @stream.verify
    end

    it "delegates select_delay" do
      @stream.expect(:select_delay, 48)
      tcp_socket.select_delay.must_equal 48
      @stream.verify
    end

    it "delegates select_delay=" do
      @stream.expect(:select_delay=, 19, [19])
      tcp_socket.select_delay = 19
      @stream.verify
    end
  end
end
