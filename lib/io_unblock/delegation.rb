module IoUnblock
  # Handles delegating read and write methods to their non-blocking
  # counterparts on the IO object. If the IO object does not support
  # non-blocking methods, falls back to blocking ones.
  module Delegation
    module NonBlockingWrites
      def io_write bytes; io.write_nonblock bytes; end
      private :io_write
    end
    
    module BlockingWrites
      def io_write bytes; io.write bytes; end
      private :io_write
    end
    
    module ForwardWriteable
      def writeable?; io.writeable?; end
      private :writeable?
    end
    
    module SelectWriteable
      def writeable?; !!IO.select(nil, io_selector, nil, 0.1); end
      private :writeable?
    end
    
    module NonBlockingReads
      def io_read len; io.read_nonblock len; end
      private :io_read
    end
    
    module PartialReads
      def io_read len; io.readpartial len; end
      private :io_read
    end
    
    module BlockingReads
      def io_read len; io.read len; end
      private :io_read
    end
    
    module ForwardReadable
      def readable?; io.readable?; end
      private :readable?
    end
    
    module SelectReadable
      def readable?; !!IO.select(io_selector, nil, nil, 0.1); end
      private :readable?
    end
    
    class << self
      def define_io_methods stream
        define_io_write stream
        define_io_read stream
      end

    private
      def define_io_write stream
        if stream.io.respond_to? :write_nonblock
          stream.extend NonBlockingWrites
        else
          stream.extend BlockingWrites
        end
        
        if stream.io.respond_to? :writeable?
          stream.extend ForwardWriteable
        else
          stream.extend SelectWriteable
        end
      end

      def define_io_read stream
        if stream.io.respond_to? :read_nonblock
          stream.extend NonBlockingReads
        elsif stream.io.respond_to? :readpartial
          stream.extend PartialReads
        else
          stream.extend BlockingReads
        end
        
        if stream.io.respond_to? :readable?
          stream.extend ForwardReadable
        else
          stream.extend SelectReadable
        end
      end
    end
  end
end
