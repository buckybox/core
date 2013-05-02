# Display a money object for ( ) to signify negative values.
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
      "(#{(-obj).format})"
    end
  end

  def negative
    MoneyDisplay.new(-obj)
  end
end
