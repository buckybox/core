require 'draper'

class ExtraDecorator < Draper::Decorator
  delegate_all

  def price
    object.price.with_currency(distributor.currency)
  end

  def with_price_per_unit
    "#{object.name} (#{price} per #{object.unit})"
  end

  def with_unit
    "#{object.name} (#{object.unit})"
  end
end
