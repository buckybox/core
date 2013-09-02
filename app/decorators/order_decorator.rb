require "draper"

class OrderDecorator < Draper::Decorator
  delegate_all

  def price
    object.price.with_currency(object.distributor.currency)
  end
end
