require File.expand_path("../../spec_helper.rb", __FILE__)

describe IoUnblock::Buffer do
  before do
    @buffer = IoUnblock::Buffer.new
  end
  
  it "should be empty when nothing is buffered" do
    @buffer.push :a, 1, 'hello'
    @buffer.pop
    @buffer.empty?.must_equal true
    @buffer.buffered?.must_equal false
  end
  
  it "should not be empty when stuff is buffered" do
    @buffer.push :a, 1, 'hello'
    @buffer.empty?.must_equal false
    @buffer.buffered?.must_equal true
  end
  
  it "should push to the end of the buffer" do
    @buffer.push :a, 1, 'hello'
    @buffer.push :b, 2, 'world'
    @buffer.first.must_equal [:a, 1, 'hello']
    @buffer.last.must_equal [:b, 2, 'world']
  end
  
  it "should unshift to the beginning of the buffer" do
    @buffer.unshift :a, 1, 'hello'
    @buffer.unshift :b, 2, 'world'
    @buffer.first.must_equal [:b, 2, 'world']
    @buffer.last.must_equal [:a, 1, 'hello']
  end
  
  it "should shift from the beginning" do
    @buffer.push :a, 1, 'hello'
    @buffer.push :b, 2, 'world'
    @buffer.shift.must_equal [:a, 1, 'hello']
  end
  
  it "should pop from the end" do
    @buffer.push :a, 1, 'hello'
    @buffer.push :b, 2, 'world'
    @buffer.pop.must_equal [:b, 2, 'world']
  end
end
