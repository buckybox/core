module Distributor::DeliveriesHelper
  def calendar_nav_length(calendar_hash)
    number_of_month_dividers = calendar_hash.map{ |ch| ch.first.strftime("%m %Y") }.uniq.length - 1
    nav_length = calendar_hash.length + number_of_month_dividers

    return "#{nav_length * 59}px"
  end

  def reschedule_dates(route)
    dates = route.schedule.next_occurrences(5, Time.now)
    options_from_collection_for_select(dates, 'to_date', 'to_date')
  end

  def order_delivery_id(order, date)
    delivery = order.delivery_for_date(date)
    delivery.id if delivery
  end

  def order_delivery_route_name(order, date)
    puts "-"*80
    puts order.inspect
    puts date.inspect
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
