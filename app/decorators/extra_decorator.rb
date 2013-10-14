require 'draper'

class ExtraDecorator < Draper::Decorator
  delegate_all

  def formatted_price
    object.price.zero? ? "Free" : object.price
  end

  def visible
    !object.hidden
  end

  def with_price_per_unit
    "#{object.name} (#{price} per #{object.unit})"
  end

  def with_unit
    "#{object.name} (#{object.unit})"
  end
end
