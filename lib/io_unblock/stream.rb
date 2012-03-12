module IoUnblock
  class StreamError < IoUnblockError; end
  
  class Stream
    MAX_BYTES_PER_WRITE = 1024 * 8
    MAX_BYTES_PER_READ = 1024 * 4
    
    attr_reader :running, :connected, :io, :io_selector, :callbacks
    attr_accessor :select_delay
    alias :running? :running
    alias :connected? :connected

    # The given IO object, `io`, is assumed to be opened/connected.
    # Global callbacks:
    # - failed: called when IO access throws an exception that cannot
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
    # - looped:  called when each time the IO processing loops
    def initialize io, callbacks=nil
      @io = io
      @io_selector = [@io]
      @processor = nil
      @s_mutex = Mutex.new
      @w_buff = IoUnblock::Buffer.new
      @running = false
      @connected = true
      @callbacks = callbacks || {}
      @select_delay = 0.1
      Delegation.define_io_methods self
      yield self if block_given?
    end
    
    def start &cb
      @s_mutex.synchronize do
        raise StreamError, "already started" if @running
        @running = true
        @processor = Thread.new do
          trigger_callbacks :started, :start, &cb
          read_and_write while running? && connected?
          flush_and_close
          trigger_callbacks :stopped, :stop, &cb
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
      @w_buff.push bytes, cb
      self
    end
    
private
    def trigger_callbacks named, *args, &other
      other && other.call(*args)
      @callbacks.key?(named) && @callbacks[named].call(*args)
    end

    def flush_and_close
      _write while connected? && @w_buff.buffered?
      io_close
      self
    end
    
    def read_and_write
      _read if read?
      _write if write?
      trigger_callbacks :looped, self
      self
    end

    def _read
      begin
        bytes = io_read MAX_BYTES_PER_READ
        trigger_callbacks(:read, bytes) if bytes
      rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
      rescue Exception
        force_close $!
      end
    end
    
    def _write
      written = 0
      while written < MAX_BYTES_PER_WRITE
        bytes, cb = @w_buff.shift
        break unless bytes
        begin
          w = io_write bytes
        rescue Errno::EINTR, Errno::EAGAIN, Errno::EWOULDBLOCK
          # writing will either block, or cannot otherwise be completed,
          # put data back and try again some other day
          @w_buff.unshift bytes, cb
          break
        rescue Exception
          force_close $!
          break
        end
        written += w
        if w < bytes.size
          @w_buff.unshift bytes[w..-1], cb
          trigger_callbacks :wrote, bytes, w
        else
          trigger_callbacks :wrote, bytes, w, &cb
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
      io_close
      trigger_callbacks :failed, ex
    end
    
    def write?
      begin
        connected? && @w_buff.buffered? && writeable?
      rescue Exception
        force_close $!
        false
      end
    end
    
    def read?
      begin
        connected? && readable?
      rescue Exception
        force_close $!
        false
      end
    end
  end
end
