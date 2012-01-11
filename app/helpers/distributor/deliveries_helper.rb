module Distributor::DeliveriesHelper
  def calendar_nav_length(calendar_hash)
    number_of_month_dividers = calendar_hash.map{ |ch| ch.first.strftime("%m %Y") }.uniq.length - 1
    nav_length = calendar_hash.length + number_of_month_dividers

    return "#{nav_length * 59}px"
  end

  def reschedule_dates(distributor)
    dates = Route.best_route(distributor).schedule.next_occurrences(5, Time.now)
    options_from_collection_for_select(dates, 'to_date', 'to_date')
  end

  #FIXME: Thes two are to compisate for a larger problem I have to revisit shortly.
  def order_delivery_id(order, date)
    delivery = order.delivery_for_date(date)
    delivery.id if delivery
  end

  def order_delivery_route_name(order, date)
    delivery = order.delivery_for_date(date)
    delivery.route.name if delivery
  end
end
