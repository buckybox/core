module Distributor::DeliveriesHelper
  CALENDAR_DATE_SIZE = 59

  def calendar_nav_length(delivery_lists)
    number_of_month_dividers = delivery_lists.group_by{|dl| dl.date.month}.size
    nav_length = delivery_lists.size + number_of_month_dividers

    return "width:#{nav_length * CALENDAR_DATE_SIZE}px;"
  end

  def date_class(date_list)
    'today' if date_list.date.today?
  end

  def count_selected(start_date, date_list, date)
    date = Date.parse(date) unless date.is_a?(Date)

    scroll_date = date - 1.week
    scroll_date = start_date if scroll_date < start_date

    if date == date_list.date
      element_id = 'selected'
    elsif scroll_date == date_list.date
      element_id = 'scroll-to'
    end

    return element_id
  end

  def count_class(date_list)
    if date_list.is_a?(FutureDeliveryList)
      'out_of_range'
    elsif !date_list.all_finished?
      'has_pending'
    end
  end

  def reschedule_dates(route)
    dates = route.schedule.next_occurrences(5, Time.current)
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

  def icon_display(status, icon_status)
    'display:none;' unless status == icon_status
  end
end
