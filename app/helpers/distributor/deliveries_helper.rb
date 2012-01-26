module Distributor::DeliveriesHelper
  def calendar_nav_length(delivery_lists)
    number_of_month_dividers = delivery_lists.group_by{|l| l.date.month}.size
    nav_length = delivery_lists.size + number_of_month_dividers

    return "#{nav_length * 59}px"
  end

  def date_status(date_list)
    class_names = []
    class_names << 'today' if date_list.date.today?

    return class_names.join(' ')
  end

  def count_status(date_list, date)
    class_names = []
    class_names << 'selected' if date_list.date.to_s == date
    class_names << 'has_pending' unless date_list.all_finished

    return class_names.join(' ')
  end

  def reschedule_dates(route)
    dates = route.schedule.next_occurrences(5, Time.now)
    options_from_collection_for_select(dates, 'to_date', 'to_date')
  end

  def order_delivery_route_name(order, date)
    delivery = order.delivery_for_date(date)
    delivery.route.name if delivery
  end

  def order_delivery_count(calendar_array, date, route = nil)
    data = calendar_array.select{|cdate, cdata| cdate == date}[0][1]

    if route
      orders = Order.find(data[:order_ids]).select{|o| o.route(date) == route}.size
    else
      data[:order_ids].size
    end
  end
end
