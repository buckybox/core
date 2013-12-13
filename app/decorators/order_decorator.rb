require "draper"

class OrderDecorator < Draper::Decorator
  delegate_all

  def price
    object.price.with_currency(object.distributor.currency)
  end

  def summary
    summary = object.box.name

    order_extras = object.order_extras
    summary << " - #{Order.extras_description(order_extras)}" if order_extras.present?

    summary
  end
end
