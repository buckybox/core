require "draper"

class BoxDecorator < Draper::Decorator
  delegate_all

  def price
    object.price.with_currency(distributor.currency)
  end
end

