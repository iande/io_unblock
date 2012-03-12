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
  
  it "flushes all writes before stopping" do
    dummy_io.writeable = false
    stream.start
    stream.write 'hello '
    stream.write 'world.'
    Thread.pass until stream.running?
    dummy_io.w_stream.string.must_equal ''
    stream.stop
    dummy_io.w_stream.string.must_equal 'hello world.'
  end

  describe "callbacks" do
    def start_cb; @start_cb ||= MiniTest::Mock.new; end
    def stop_cb; @stop_cb ||= MiniTest::Mock.new; end
    def fail_cb; @fail_cb ||= MiniTest::Mock.new; end
    def wrote_cb; @wrote_cb ||= MiniTest::Mock.new; end
    def read_cb; @read_cb ||= MiniTest::Mock.new; end
    def close_cb; @close_cb ||= MiniTest::Mock.new; end

    def callback_stream cbs=nil
      IoUnblock::Stream.new(dummy_io, cbs)
    end

    it "triggers started when starting" do
      cb_stream = callback_stream(started: start_cb)
      start_cb.expect(:call, nil, [:start])
      cb_stream.start
      cb_stream.stop
      start_cb.verify
    end

    it "triggers stopped when stopping" do
      cb_stream = callback_stream(stopped: stop_cb)
      stop_cb.expect(:call, nil, [:stop])
      cb_stream.start
      cb_stream.stop
      stop_cb.verify
    end

    it "triggers wrote when writing" do
      dummy_io.max_write = 3
      wrote_cb.expect(:call, nil, ['hel', 3])
      wrote_cb.expect(:call, nil, ['lo', 2])
      cb_stream = callback_stream(wrote: wrote_cb)
      cb_stream.start
      cb_stream.write "hello"
      cb_stream.stop
      wrote_cb.verify
    end

    it "triggers read when reading" do
      dummy_io.max_read = 3
      dummy_io.r_stream.string = 'hello'
      read_cb.expect(:call, nil, ['hel'])
      read_cb.expect(:call, nil, ['lo'])
      cb_stream = callback_stream(read: read_cb)
      cb_stream.start
      Thread.pass until dummy_io.r_stream.eof?
      cb_stream.stop
      read_cb.verify
    end

    it "triggers closed when closing" do
      close_cb.expect(:call, nil, [])
      cb_stream = callback_stream(closed: close_cb)
      cb_stream.start
      cb_stream.stop
      close_cb.verify
    end

    it "triggers failed when reading raises an error" do
      err = RuntimeError.new "fail"
      fail_cb.expect(:call, nil, [err])
      cb_stream = callback_stream(failed: fail_cb)
      dummy_io.raise_read = err
      cb_stream.start
      Thread.pass until cb_stream.running?
      Thread.pass while cb_stream.connected?
      cb_stream.stop
      fail_cb.verify
    end

    it "triggers failed when writing raises an error" do
      err = RuntimeError.new "fail"
      fail_cb.expect(:call, nil, [err])
      cb_stream = callback_stream(failed: fail_cb)
      dummy_io.raise_write = err
      cb_stream.start
      cb_stream.write "hello"
      cb_stream.stop
      fail_cb.verify
    end
    
    it "triggers the given callback when starting and stopping" do
      called_with = []
      stream.start { |state| called_with << state }
      stream.stop
      called_with.must_equal [:start, :stop]
    end

    it "triggers the given callback after writing the full string" do
      called_with = []
      dummy_io.max_write = 3
      stream.start
      stream.write('hello') { |wrote, len| called_with << [wrote, len] }
      stream.stop
      called_with.must_equal [ ['lo', 2] ]
    end
  end
end
