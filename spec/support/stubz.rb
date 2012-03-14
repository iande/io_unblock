module Stubz
  def self.included base
    base.__send__(:before) { _ensure_stubs_ }
    base.__send__(:after) { _reset_stubs_ }
  end

  def stub_instance(klass, meth, *val, &block)
    _do_stub_ klass, meth, *val, &block
  end

  def stub(obj, meth, *val, &block)
    _do_stub_ get_meta_class(obj), meth, *val, &block
  end

  def get_meta_class klass
    class << klass; self; end
  end

  def _do_stub_ klass, meth, *val, &block
    if klass.method_defined? meth
      aliased = "_stub_#{meth}_#{Time.now.to_i}_"
      klass.send(:alias_method, aliased, meth)
    else
      aliased = nil
    end
    if block
      klass.send(:define_method, meth, &block)
    else
      klass.send(:define_method, meth) do |*_|
        val.first
      end
    end
    @stubbies << [klass, meth, aliased]
  end

  def _ensure_stubs_
    @stubbies = []
  end

  def _reset_stubs_
    @stubbies.each do |(klass, meth, aliased)|
      klass.send(:remove_method, meth)
    if aliased
      klass.send(:alias_method, meth, aliased)
      klass.send(:remove_method, aliased)
    end
    end
  end
end
