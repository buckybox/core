class MoneyDisplay
  attr_accessor :obj

  def initialize(obj)
    raise "Object must respond to .format" unless obj.respond_to?(:format)
    self.obj = obj
  end

  def method_missing(*args)
    obj.send(args[0], *args[1..-1])
  end

  def to_s
    if obj >= 0
      obj.format
    else
      "(#{(obj*-1.0).format})"
    end
  end

  def negative
    MoneyDisplay.new(obj*-1)
  end
end
