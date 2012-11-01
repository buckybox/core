module Distributor::CustomersHelper
  def next_customer_delivery_occurrence(customer)
    next_occurrence = customer.next_order_occurrence_date
    if next_occurrence.blank? || next_occurrence < Date.current
      nil
    elsif next_occurrence == Date.current
      'Today'
    elsif next_occurrence == Date.current.tomorrow
      'Tomorrow'
    elsif next_occurrence && (next_occurrence < (Date.current + 6.days))
      next_occurrence.to_s(:weekday)
    elsif next_occurrence
      next_occurrence.to_s(:day_month_and_year)
    end
  end

  def next_customer_delivery_box_name(customer)
    order = customer.next_order
    order.box.name if order
  end
end
