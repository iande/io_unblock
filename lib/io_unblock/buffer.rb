module IoUnblock
  # A very simple synchronized buffer.
  #
  # @api private
  class Buffer
    
    def initialize
      @buffer = []
      @mutex = Mutex.new
    end
    
    def push bytes, cb
      synched { @buffer.push [bytes, cb] }
    end
    
    def pop
      synched { @buffer.pop }
    end
        
    def unshift bytes, cb
      synched { @buffer.unshift [bytes, cb] }
    end
    
    def shift
      synched { @buffer.shift }
    end
    
    def first
      synched { @buffer.first }
    end
    
    def last
      synched { @buffer.last }
    end
    
    def empty?
      # Should we lock?
      @buffer.empty?
    end
    
    def buffered?
      !empty?
    end

private
    def synched &block
      @mutex.synchronize(&block)
    end
  end
end
