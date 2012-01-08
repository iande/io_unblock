module IoUnblock
  require 'thread'
  
  class Stream
    MAX_BYTES_PER_WRITE = 1024 * 8
    MAX_BYTES_PER_READ = 1024 * 4
    
    attr_reader :running, :connected
    alias :running? :running
    alias :connected? :connected

    # The given IO object, `io`, is assumed to be opened/connected.
    # Global callbacks:
    # - failure: called when IO access throws an exception that cannot
    #            be recovered from (opening the IO fails,
    #            TCP connection reset, unexpected EOF, etc.)
    # - read:    called when any data is read from the underlying IO
    #            object
    # - wrote:   called when any data is written to the underlying IO
    #            object
    # - closed:  called when the underlying IO object is closed (even
    #            if it is closed as a result of a failure)
    # - started: called when the IO processing has started
    # - stopped: called when the IO processing has stopped
    def initialize io, callbacks=nil
      @io = io
      @processor = nil
      @s_mutex = Mutex.new
      @w_mutex = Mutex.new
      @w_buff = []
      @running = false
      @connected = true
      @callbacks = callbacks || {}
      setup_delegation
    end
    
    def start &cb
      @s_mutex.synchronize do
        unless @running
          @running = true
          @processor = Thread.new do
            trigger_callbacks :started, :start, &cb
            io_loop while running? && connected?
            flush_and_close
            trigger_callbacks :stopped, :stop, &cb
          end
        end
      end
      self
    end
    
    def stop
      @s_mutex.synchronize do
        if @running
          @running = false
          @processor.join
        end
      end
      self
    end
    
    # The callback triggered here will be invoked only when all bytes
    # have been written.
    def write bytes, &cb
      push_write bytes, cb
      self
    end
    
private
    def trigger_callbacks named, *args, &other
      other && other.call(*args)
      @callbacks.key?(named) && @callbacks[named].call(*args)
    end

    def flush_and_close
      io_write while connected? && !@w_buff.empty?
      io_close
      self
    end
    
    def io_loop
      io_read
      io_write
      self
    end

    def io_read
      if read_ready?
        begin
          bytes = read_nonblock MAX_BYTES_PER_READ
          trigger_callbacks :read, bytes
        rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
        rescue EOFError
          force_close $!
        rescue Exception
          force_close $!
        end
      end
    end
    
    def io_write
      if write_ready?
        written = 0
        while written < MAX_BYTES_PER_WRITE
          bytes, cb = shift_write
          break unless bytes
          begin
            w = write_nonblock bytes
          rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
            # writing will either block, or cannot otherwise be completed,
            # put data back and try again some other day
            unshift_write bytes, cb
            break
          rescue Exception
            force_close $!
            break
          end
          written += w
          if w < bytes.size
            unshift_write bytes[w..-1], cb
            trigger_callbacks :wrote, bytes, w
          else
            trigger_callbacks :wrote, bytes, w, &cb
          end
        end
      end
    end

    def io_close
      if connected?
        @io.close rescue nil
        @connected = false
        trigger_callbacks :closed
      end
    end
    
    def force_close ex
      trigger_callbacks :failure, ex
      io_close
    end
    
    def write_ready?
      begin
        connected? && @w_buff.size > 0 && IO.select(nil, [@io], nil, 0.1)
      rescue Exception
        force_close $!
        false
      end
    end
    
    def read_ready?
      begin
        connected? && IO.select([@io], nil, nil, 0.1)
      rescue Exception
        force_close $!
        false
      end
    end
    
    def push_write bytes, cb
      @w_mutex.synchronize { @w_buff.push [bytes, cb] }
    end
    
    def shift_write
      @w_mutex.synchronize { @w_buff.shift }
    end
    
    def unshift_write bytes, cb
      @w_mutex.synchronize { @w_buff.unshift [bytes, cb] }
    end
    
    def setup_delegation
      setup_write_delegation
      setup_read_delegation
    end
    
    def setup_write_delegation
      if @io.respond_to? :write_nonblock
        def self.write_nonblock bytes; @io.write_nonblock bytes; end
      else
        def self.write_nonblock bytes; @io.write bytes; end
      end
    end
    
    def setup_read_delegation
      if @io.respond_to? :read_nonblock
        def self.read_nonblock sz; @io.read_nonblock sz; end
      else
        def self.read_nonblock sz; @io.readpartial sz; end
      end
    end
  end
end
