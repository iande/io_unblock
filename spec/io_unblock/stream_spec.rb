require File.expand_path("../../spec_helper.rb", __FILE__)
require 'stringio'
require 'logger'

$log = Logger.new $stdout

describe IoUnblock::Stream do
  def dummy_io; @dummy_io ||= DummyIO.new; end
  def stream; @stream ||= IoUnblock::Stream.new dummy_io; end
  
  it "raises an exception if started twice" do
    stream.start
    lambda {
      stream.start
    }.must_raise IoUnblock::StreamError
    stream.stop
  end
  
  it "reads only if the IO is ready for it" do
    dummy_io.r_stream.string = 'test string'
    dummy_io.readable = false
    stream.start
    Thread.pass until stream.running?
    dummy_io.r_stream.pos.must_equal 0
    dummy_io.readable = true
    Thread.pass until dummy_io.r_stream.eof?
    stream.stop
    dummy_io.r_stream.pos.must_equal 11
  end
  
  it "closes the io when stopping" do
    dummy_io.closed?.must_equal false
    stream.start
    Thread.pass until stream.running?
    stream.stop
    dummy_io.closed?.must_equal true
  end
  
  it "flushes all writes before stopping (even if io claims to be unwriteable)" do
    dummy_io.writeable = false
    stream.start
    stream.write 'hello '
    stream.write 'world.'
    Thread.pass until stream.running?
    dummy_io.w_stream.string.must_equal ''
    stream.stop
    dummy_io.w_stream.string.must_equal 'hello world.'
  end

  it "does not die on EINTER" do
    dummy_io.raise_write = Errno::EINTR.new
    dummy_io.raise_read = Errno::EINTR.new
    stream.start
    stream.write 'hello'
    Thread.pass until dummy_io.raised_read?
    stream.connected?.must_equal true
    dummy_io.raise_read = nil
    Thread.pass until dummy_io.raised_write?
    stream.connected?.must_equal true
    dummy_io.raise_write = nil
    stream.stop
    dummy_io.w_stream.string.must_equal 'hello'
  end

  it "does not die on EAGAIN" do
    dummy_io.raise_write = Errno::EAGAIN.new
    dummy_io.raise_read = Errno::EINTR.new
    stream.start
    stream.write 'hello'
    Thread.pass until dummy_io.raised_read?
    stream.connected?.must_equal true
    dummy_io.raise_read = nil
    Thread.pass until dummy_io.raised_write?
    stream.connected?.must_equal true
    dummy_io.raise_write = nil
    stream.stop
    dummy_io.w_stream.string.must_equal 'hello'
  end

  it "does not die on EWOULDBLOCK" do
    dummy_io.raise_write = Errno::EWOULDBLOCK.new
    dummy_io.raise_read = Errno::EINTR.new
    stream.start
    stream.write 'hello'
    Thread.pass until dummy_io.raised_read?
    stream.connected?.must_equal true
    dummy_io.raise_read = nil
    Thread.pass until dummy_io.raised_write?
    stream.connected?.must_equal true
    dummy_io.raise_write = nil
    stream.stop
    dummy_io.w_stream.string.must_equal 'hello'
  end

  describe "callbacks" do
    def called_with; @calls_received ||= []; end
    def callback; @callback ||= lambda { |*a| called_with << a }; end

    def callback_stream cbs=nil
      IoUnblock::Stream.new(dummy_io, cbs)
    end

    it "triggers started when starting" do
      cb_stream = callback_stream(started: callback)
      cb_stream.start
      cb_stream.stop
      called_with.must_equal [ [:start] ]
    end

    it "triggers stopped when stopping" do
      cb_stream = callback_stream(stopped: callback)
      cb_stream.start
      cb_stream.stop
      called_with.must_equal [ [:stop] ]
    end

    it "triggers looped after each read/write cycle" do
      cb_stream = callback_stream(looped: callback)
      cb_stream.start
      Thread.pass while called_with.empty?
      cb_stream.stop
      called_with.first.must_equal [cb_stream]
    end

    it "triggers wrote when writing" do
      dummy_io.max_write = 3
      cb_stream = callback_stream(wrote: callback)
      cb_stream.start
      cb_stream.write "hello"
      cb_stream.stop
      called_with.must_equal [ ['hello', 3], ['lo', 2] ]
    end

    it "triggers read when reading" do
      dummy_io.max_read = 3
      dummy_io.r_stream.string = 'hello'
      cb_stream = callback_stream(read: callback)
      cb_stream.start
      Thread.pass until dummy_io.r_stream.eof?
      cb_stream.stop
      called_with.must_equal [ ['hel'], ['lo'] ]
    end

    it "triggers closed when closing" do
      cb_stream = callback_stream(closed: callback)
      cb_stream.start
      cb_stream.stop
      called_with.must_equal [ [] ]
    end

    it "triggers failed when reading raises an error" do
      err = RuntimeError.new "fail"
      cb_stream = callback_stream(failed: callback)
      dummy_io.raise_read = err
      cb_stream.start
      Thread.pass until cb_stream.running?
      Thread.pass while cb_stream.connected?
      cb_stream.stop
      called_with.must_equal [ [err] ]
    end

    it "triggers failed when writing raises an error" do
      err = RuntimeError.new "fail"
      cb_stream = callback_stream(failed: callback)
      dummy_io.raise_write = err
      cb_stream.start
      cb_stream.write "hello"
      cb_stream.stop
      called_with.must_equal [ [err] ]
    end
    
    it "triggers the given callback when starting and stopping" do
      stream.start(&callback)
      stream.stop
      called_with.must_equal [ [:start], [:stop]]
    end

    it "triggers the given callback after writing the full string" do
      dummy_io.max_write = 3
      stream.start
      stream.write('hello', &callback)
      stream.stop
      called_with.must_equal [ ['lo', 2] ]
    end
    
    it "is not connected when failed is triggered" do
      is_connected = true
      cb_stream = callback_stream(
        failed: lambda { |ex| is_connected = cb_stream.connected? }
      )
      err = RuntimeError.new "fail"
      dummy_io.raise_write = err
      cb_stream.start
      cb_stream.write "hello"
      cb_stream.stop
      is_connected.must_equal false
    end
  end
end
