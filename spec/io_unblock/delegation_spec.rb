require File.expand_path("../../spec_helper.rb", __FILE__)

describe IoUnblock::Delegation do
  class FakeStream
    attr_reader :io
    def initialize io
      @io = io
    end
    def io_selector; [@io]; end
    def select_delay; 18; end
  end
  
  before do
    @mock_io = MiniTest::Mock.new
    @stream = FakeStream.new @mock_io
  end
  
  it "delegates to read_nonblock when available" do
    @mock_io.expect(:read_nonblock, :reading, [42])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_read, 42
    @mock_io.verify
  end
  
  it "delegates to readpartial when available" do
    @mock_io.expect(:readpartial, :reading, [42])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_read, 42
    @mock_io.verify
  end
  
  it "delegates to read if all else fails" do
    @mock_io.expect(:read, :reading, [42])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_read, 42
    @mock_io.verify
  end
  
  it "delegates to write_nonblock when available" do
    @mock_io.expect(:write_nonblock, :writing, ['hello'])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_write, 'hello'
    @mock_io.verify
  end
  
  it "delegates to write if all else fails" do
    @mock_io.expect(:write, :writing, ['hello'])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :io_write, 'hello'
    @mock_io.verify
  end

  it "delegates to IO.select when there is no readable? method" do
    mocked = MiniTest::Mock.new
    mocked.expect(:select, nil, [[@mock_io], nil, nil, 18])
    real_io = IO
    ::IO = mocked
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :readable?
    ::IO = real_io
    mocked.verify
  end

  it "delegates to IO.select when there is no writeable? method" do
    mocked = MiniTest::Mock.new
    mocked.expect(:select, nil, [nil, [@mock_io], nil, 18])
    real_io = IO
    ::IO = mocked
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :writeable?
    ::IO = real_io
    mocked.verify
  end

  it "delegates to readable? when the method is available" do
    @mock_io.expect(:readable?, false, [])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :readable?
    @mock_io.verify
  end

  it "delegates to writeable? when the method is available" do
    @mock_io.expect(:writeable?, false, [])
    IoUnblock::Delegation.define_io_methods @stream
    @stream.__send__ :writeable?
    @mock_io.verify
  end
end
