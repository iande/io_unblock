module IoUnblock
  # A very simple synchronized buffer.
  class Buffer
    
    def initialize
      @buffer = []
      @mutex = Mutex.new
    end
    
    def push bytes, cb
      @mutex.synchronize { @buffer.push [bytes, cb] }
    end
    
    def pop
      @mutex.synchronize { @buffer.pop }
    end
        
    def unshift bytes, cb
      @mutex.synchronize { @buffer.unshift [bytes, cb] }
    end
    
    def shift
      @mutex.synchronize { @buffer.shift }
    end
    
    def first
      @mutex.synchronize { @buffer.first }
    end
    
    def last
      @mutex.synchronize { @buffer.last }
    end
    
    def empty?
      # Should we lock?
      @buffer.empty?
    end
    
    def buffered?
      !empty?
    end
  end
end
