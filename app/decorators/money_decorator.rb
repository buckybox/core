require 'draper'

class MoneyDecorator < Draper::Decorator
  delegate_all

  def to_s
    object.positive? ? object.format : negative_format
  end

  def negative
    MoneyDecorator.decorate(-object)
  end

private

  def negative_format
    money = -object
    "(#{money.format})"
  end
end
