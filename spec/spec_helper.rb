if ENV['SCOV']
  require 'simplecov'
  SimpleCov.start do
    puts "I am started?! #{Process.pid}"
    add_filter "/spec/"
  end
end

require 'minitest/autorun'
require 'minitest/emoji'
require 'io_unblock'
require 'stringio'

# Used to test IO stuff, using stringio objects for the write and
# read stream.
class DummyIO
  attr_reader :closed, :w_stream, :r_stream, :raised_write, :raised_read
  alias :closed? :closed
  alias :raised_write? :raised_write
  alias :raised_read? :raised_read
  attr_accessor :readable, :writeable
  attr_accessor :write_delay, :read_delay
  attr_accessor :max_write, :max_read
  attr_accessor :raise_read, :raise_write
  alias :readable? :readable
  alias :writeable? :writeable
  
  def initialize *args, &block
    @r_stream = StringIO.new
    @w_stream = StringIO.new
    @readable = @writeable = true
    @read_delay = @write_delay = 0
    @max_write = 0
    @max_read = 0
    @closed = false
    @raise_read = nil
    @raise_write = nil
    @raised_write = false
    @raised_read = false
  end
  
  def close
    @closed = true
    @w_stream.close
    @r_stream.close
  end
  
  def write_nonblock bytes
    sleep(@write_delay) if @write_delay > 0
    do_raise_write
    if @max_write > 0 && bytes.size > @max_write
      @w_stream.write bytes[0...@max_write]
    else
      @w_stream.write bytes
    end
  end
  
  def read_nonblock len
    sleep(@read_delay) if @read_delay > 0
    do_raise_read
    if @max_read > 0 && len > @max_read
      @r_stream.read @max_read
    else
      @r_stream.read len
    end
  end

  def do_raise_write
    if @raise_write
      @raised_write = true
      raise @raise_write
    end
  end

  def do_raise_read
    if @raise_read
      @raised_read = true
      raise @raise_read
    end
  end
end
