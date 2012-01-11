require File.expand_path("../../spec_helper.rb", __FILE__)
require 'stringio'
require 'logger'

$log = Logger.new $stdout

describe IoUnblock::Stream do  
  before do
    @io = DummyIO.new
  end
  
  it "should raise an exception if started twice" do
    @stream = IoUnblock::Stream.new(@io)
    @stream.start
    lambda {
      @stream.start
    }.must_raise IoUnblock::StreamError
    @stream.stop
  end
  
  it "should only read if the IO is ready for it" do
    @io.r_stream.string = 'test string'
    @io.readable = false
    @stream = IoUnblock::Stream.new @io
    @stream.start
    Thread.pass until @stream.running?
    @io.r_stream.pos.must_equal 0
    @io.readable = true
    Thread.pass until @io.r_stream.eof?
    @stream.stop
    @io.r_stream.pos.must_equal 11
  end
  
  it "should close the io when stopping" do
    @stream = IoUnblock::Stream.new @io
    @io.closed?.must_equal false
    @stream.start
    Thread.pass until @stream.running?
    @stream.stop
    @io.closed?.must_equal true
  end
  
  it "should flush all writes before stopping" do
    @io.writeable = false
    @stream = IoUnblock::Stream.new @io
    @stream.start
    @stream.write 'hello '
    @stream.write 'world.'
    Thread.pass until @stream.running?
    @io.w_stream.string.must_equal ''
    @stream.stop
    @io.w_stream.string.must_equal 'hello world.'
  end
  
end

# {
#   started: lambda { |s| puts "Started: #{s}" },
#   stopped: lambda { |s| puts "Stopped: #{s}" },
#   failure: lambda { |ex| puts "Failed: #{ex}" }
# }