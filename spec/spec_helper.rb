if ENV['SCOV']
  require 'simplecov'
  SimpleCov.start do
    puts "I am started?! #{Process.pid}"
    add_filter "/spec/"
  end
end

require 'minitest/autorun'
require 'io_unblock'
require 'stringio'

# Used to test IO stuff, using stringio objects for the write and
# read stream.
class DummyIO
  attr_reader :closed, :w_stream, :r_stream
  alias :closed? :closed
  attr_accessor :readable, :writeable
  attr_accessor :write_delay, :read_delay
  attr_accessor :max_write, :max_read
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
  end
  
  def close
    @closed = true
    @w_stream.close
    @r_stream.close
  end
  
  def write_nonblock bytes
    sleep(@write_delay) if @write_delay > 0
    if @max_write > 0 && bytes.size > @max_write
      @w_stream.write bytes[0...@max_write]
    else
      @w_stream.write bytes
    end
  end
  
  def read_nonblock len
    sleep(@read_delay) if @read_delay > 0
    if @max_read > 0 && len > @max_read
      puts "Only reading: #{@max_read} bytes"
      @r_stream.read @max_read
    else
      @r_stream.read len
    end
  end
end