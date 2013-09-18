require 'draper'

class ExtraDecorator < Draper::Decorator
  delegate_all

  def price
    object.price.with_currency(distributor.currency)
  end

  def with_units
    "#{object.name} (#{object.unit})"
  end
end
