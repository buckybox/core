module Distributor::CustomersHelper
  def next_customer_delivery_occurrence(customer)
    next_occurrence = customer.next_delivery_time

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

  def order_customisation(order)
    description = order.customisation_description
    content_tag(:span, truncate(description), title: description)
  end

  def order_extras(order)
    description = order.extras_description(true)
    content_tag(:span, truncate(description), title: description)
  end

  def order_pause_select(order)
    order.schedule.next_occurrences(8).map { |s| [s.to_date.to_s(:pause), s.to_date] }
  end

  def order_resume_select(order)
    order.schedule.next_occurrences(8).map { |s| [s.to_date.to_s(:pause), s.to_date] }
  end
end
