require 'thread'
require "io_unblock/version"

module IoUnblock
  class IoUnblockError < StandardError; end
end

require 'io_unblock/delegation'
require 'io_unblock/buffer'
require 'io_unblock/stream'
