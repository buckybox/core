module Distributor::CustomersHelper
  def next_customer_delivery_occurrence(customer)
    next_occurrence = Time.parse(customer.next_occurrence)

    if next_occurrence && (next_occurrence < (Time.current + 6.days))
      next_occurrence.to_s(:weekday)
    elsif next_occurrence
      next_occurrence.to_s(:day_month_and_year)
    end
  end

  def next_customer_delivery_box_name(customer)
    order = customer.order_with_next_delivery
    order.box.name if order
  end
end
