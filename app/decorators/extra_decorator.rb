require 'draper'

class ExtraDecorator < Draper::Decorator
  delegate_all

  def formatted_price
    object.price.zero? ? "Free" : price_with_currency
  end

  def visible
    !object.hidden
  end

  def price_with_currency
    object.price.with_currency(object.distributor.currency)
  end

  def with_price_per_unit
    "#{object.name} (#{price_with_currency} per #{object.unit})"
  end

  def with_unit
    "#{object.name} (#{object.unit})"
  end
end
