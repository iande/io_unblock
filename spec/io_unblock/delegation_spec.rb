require File.expand_path("../../spec_helper.rb", __FILE__)

describe IoUnblock::Delegation do
  class FakeStream
    attr_reader :io
    def initialize io
      @io = io
    end
  end
  
  before do
    @mock_io = MiniTest::Mock.new
    @stream = FakeStream.new @mock_io
  end
  
  it "should delegate to read_nonblock when available" do
    @mock_io.expect(:read_nonblock, :reading, [42])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_read, 42
    @mock_io.verify
  end
  
  it "should delegate to readpartial when available" do
    @mock_io.expect(:readpartial, :reading, [42])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_read, 42
    @mock_io.verify
  end
  
  it "should delegate to read if all else fails" do
    @mock_io.expect(:read, :reading, [42])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_read, 42
    @mock_io.verify
  end
  
  it "should delegate to write_nonblock when available" do
    @mock_io.expect(:write_nonblock, :writing, ['hello'])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_write, 'hello'
    @mock_io.verify
  end
  
  it "should delegate to write if all else fails" do
    @mock_io.expect(:write, :writing, ['hello'])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_write, 'hello'
    @mock_io.verify
  end
end
