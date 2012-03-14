if ENV['SCOV']
  require 'simplecov'
  SimpleCov.start do
    puts "I am started?! #{Process.pid}"
    add_filter "/spec/"
  end
end

begin
  require 'minitest/autorun'
  require 'minitest/emoji'
rescue LoadError
end

Dir[File.expand_path('../support/*.rb', __FILE__)].each do |r|
  require r
end

require 'io_unblock'

