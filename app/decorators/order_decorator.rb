require "draper"

class OrderDecorator < Draper::Decorator
  delegate_all

  def price
    object.price.with_currency(object.distributor.currency)
  end

  def summary
    summary = "* #{object.box.name}"
    order_extras = object.order_extras

    if order_extras.present?
      extras_description = Order.extras_description(order_extras, "\n")
      extras_count = extras_description.count("\n") + 1

      summary << " <em>with additional extra item#{'s' if extras_count > 1} of</em>:\n#{extras_description}"
    end

    summary
  end
end
