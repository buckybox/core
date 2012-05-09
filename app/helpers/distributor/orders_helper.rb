module Distributor::OrdersHelper
  def order_frequencies
    Order::FREQUENCIES.map{ |frequencies| [frequencies.titleize, frequencies] }
  end

  def order_start_dates(route, count = 28)
    next_occurrences = route.schedule.next_occurrences(count, route.distributor.window_end_at.to_time_in_current_zone)
    return next_occurrences.map { |time| [time.strftime("%A, %B %d, %Y"), time.to_date] }
  end

  def all_order_start_dates(distributor, count = 10)
    next_occurrences = distributor.routes.inject([]) { |a,r| a += order_start_dates(r, count); a }
    return next_occurrences.uniq.sort{ |a,b| a[1] <=> b[1] }
  end
end
